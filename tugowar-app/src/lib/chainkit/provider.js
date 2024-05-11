import { ethers } from "ethers";

import {
  isAsync,
  isUndefined,
  etherrmsg,
  constructedLikeClass,
} from "../idioms.js";
import { getLogger } from "../log.js";

const log = getLogger("eip1193/provider");

export class EIP1193ProviderContext {
  constructor(cfg = {}) {
    this._init(cfg);

    const { accountsChanged, chainChanged, disconnected } = cfg;

    this._accountsChanged = async (accounts) => {
      this.accounts = accounts;

      const { signer, signerAddress } = await getSignerAddress(
        this.provider,
        this.addressOrIndex
      );
      this.signer = signer;
      this.signerAddress = signerAddress;

      if (!accountsChanged) return;

      if (isAsync(accountsChanged)) return await accountsChanged(this);
      return accountsChanged(this);
    };

    this._chainChanged = async (chainId) => {
      this.chainId = alwaysNumber(chainId);
      const { signer, signerAddress } = await getSignerAddress(
        this.provider,
        this.addressOrIndex
      );
      this.signer = signer;
      this.signerAddress = signerAddress;

      if (!chainChanged) return;

      if (isAsync(chainChanged)) {
        return await chainChanged(this);
      }
      return chainChanged(this);
    };

    this._disconnected = async (err) => {
      if (err) log.info("provider disconnected", err);
      this.stopListening(); // pause rather than reset so that a trivial reconnect is possible

      if (!disconnected) return;

      if (isAsync(disconnected)) {
        await disconnected(ctx, err);
      } else {
        disconnected(ctx, err);
      }
    };
  }

  async setProvider(
    eip1193Provider,
    addressOrIndex = undefined,
    chainId = undefined
  ) {
    this.stopListening();

    if (typeof addressOrIndex === "undefined")
      addressOrIndex = this.addressOrIndex;

    const prepared = await setProvider(
      eip1193Provider,
      addressOrIndex,
      chainId,
      {
        accountsChanged: this._accountsChanged,
        chainChanged: this._chainChanged,
        disconnected: this._disconnected,
      }
    );

    this.provider = prepared.provider;
    this.request = prepared.request;
    this.eip1193Provider = eip1193Provider;
    this.chainId = prepared.chainId;
    this.evmProviderType = prepared.evmProviderType;
    this.signer = prepared.signer;
    this.signerAddress = prepared.signerAddress;
    this.accounts = prepared.accounts;
    this.addressOrIndex = prepared.addressOrIndex;
  }

  stopListening() {
    if (this.eip1193Provider?.removeAllListeners) {
      this.eip1193Provider.removeAllListeners();
    }
  }

  async resume() {
    return this.setProvider(this.eip1193Provider, this.addressOrIndex);
  }

  _init(cfg) {
    this.eip1193Provider = undefined;
    this.addressOrIndex = cfg?.addressOrIndex;

    this.provider = undefined;
    this.request = undefined;
    this.eip1193Provider = undefined;
    this.chainId = undefined;
    this.evmProviderType = undefined;
    this.signer = undefined;
    this.signerAddress = undefined;
    this.accounts = undefined;
  }

  reset() {
    this.stopListening();
    this._init();
  }
}

export async function getSignerAddress(provider, addressOrIndex) {
  let signer, signerAddress;

  try {
    // XXX some providers do not support getSigner
    // if (
    //   typeof provider.listAccounts === "function" &&
    //   (addressOrIndex === null || typeof addressOrIndex === "undefined")
    // ) {
    //   signer = provider.getSigner();
    // } else {
    //   signer = provider.getSigner(addressOrIndex);
    // }
    signer = provider.getSigner(addressOrIndex);
    signerAddress = await signer.getAddress();
  } catch (err) {
    log.info(
      "failed to get signer and address from provider, not all providers support this"
    );
  }
  return { signer, signerAddress };
}

export async function setProvider(
  provider,
  addressOrIndex = 0,
  { chainId, accountsChanged, chainChanged, disconnected } = {}
) {
  if (!provider) {
    provider = getWindowEthereum();
    if (!provider)
      throw new Error(
        "Please authorize browser extension (Metamask or similar) or provide an RPC based provider"
      );
    provider.autoRefreshOnNetworkChange = false;
    const prepared = await prepare1193Provider(
      provider,
      addressOrIndex,
      chainId,
      {
        accountsChanged,
        chainChanged,
        disconnected,
      }
    );

    // Wrap the injected provider in a Web3 to make it behave consistently
    prepared.provider = new ethers.providers.Web3Provider(prepared.provider);
    const { signer, signerAddress } = await getSignerAddress(
      provider,
      addressOrIndex
    );
    prepared.signer = signer;
    prepared.signerAddress = signerAddress;
    return prepared;
  }

  // If we already have a Web3Provider wrapper, prepare the original provider
  // again and make a fresh wrapper
  if (constructedLikeClass(provider, ethers.providers.Web3Provider)) {
    log.debug("EIP1193ProviderContext#setProvider: Web3Provider");
    const prepared = await prepare1193Provider(
      provider.provider,
      addressOrIndex,
      chainId,
      {
        accountsChanged,
        chainChanged,
        disconnected,
      }
    );
    prepared.provider = new ethers.providers.Web3Provider(prepared.provider);
    const { signer, signerAddress } = await getSignerAddress(
      provider,
      addressOrIndex
    );
    prepared.signer = signer;
    prepared.signerAddress = signerAddress;
    log.info(
      `EIP1193ProviderContext#setProvider: prepared.signerAddress: ${prepared.signerAddress}`
    );
    return prepared;
  }
  log.debug("EIP1193ProviderContext#setProvider: NOT Web3Provider");

  // If the caller wants an explicitly provider type,eg the not-polling
  // StaticJsonRpcProvider, they can just intsance it and pass it in and this
  // case deals with it.
  if (typeof provider === "object" && provider.request) {
    log.debug("EIP1193ProviderContext#setProvider: has request");

    const prepared = await prepare1193Provider(
      provider,
      addressOrIndex,
      chainId,
      {
        accountsChanged,
        chainChanged,
        disconnected,
      }
    );
    const { signer, signerAddress } = await getSignerAddress(
      provider,
      addressOrIndex
    );
    prepared.signer = signer;
    prepared.signerAddress = signerAddress;
    log.info(
      `EIP1193ProviderContext#setProvider: prepared.signerAddress: ${prepared.signerAddress}`
    );
    return prepared;
  }

  if (
    typeof provider !== "object" ||
    (!constructedLikeClass(provider, ethers.providers.BaseProvider) &&
      !constructedLikeClass(provider, ethers.providers.UrlJsonRpcProvider))
  ) {
    log.debug("EIP1193ProviderContext#setProvider: forcing json rpc");

    provider = new ethers.providers.JsonRpcProvider(provider);
  }
  log.debug("EIP1193ProviderContext#setProvider: assume generic 1193");

  const prepared = await prepare1193Provider(
    provider,
    addressOrIndex,
    chainId,
    {
      accountsChanged,
      chainChanged,
      disconnected,
    }
  );
  const { signer, signerAddress } = await getSignerAddress(
    provider,
    addressOrIndex
  );
  prepared.signer = signer;
  prepared.signerAddress = signerAddress;
  log.info(
    `EIP1193ProviderContext#setProvider: prepared.signerAddress: ${prepared.signerAddress}`
  );
  return prepared;
}

/**
 * accountsChanged may be used as the accountsChanged callback for EIP1193ProviderContext
 * @param {*} ctx
 * @returns
 */
export async function accountsChanged(ctx) {
  return prepare1193Provider(
    ctx.eip1193Provider,
    Array.isArray(ctx.accounts) && ctx.accounts.length ? ctx.accounts[0] : 0,
    ctx.chainId
  );
}

/**
 * chainChanged may be used as the corresponding callback for EIP1193ProviderContext
 * @param {*} ctx
 * @returns
 */
export async function chainChanged(ctx) {
  return prepare1193Provider(
    ctx.eip1193Provider,
    Array.isArray(ctx.accounts) && ctx.accounts.length ? ctx.accounts[0] : 0,
    ctx.chainId
  );
}

/**
 * disconnected may be used as the corresponding callback for EIP1193ProviderContext
 * @param {*} ctx
 * @returns
 */
export function disconnected(ctx, err) {
  log.info(
    `provider ${ctx.eipProvider?.constructor?.name} disconnected: ${err}`
  );
}

export function removeListeners(
  eip1193Provider,
  { accountsChanged, chainChanged, disconnected }
) {
  if (!eip1193Provider?.removeListener) return;
  if (accountsChanged)
    eip1193Provider.removeListener("accountsChanged", accountsChanged);
  if (chainChanged)
    eip1193Provider.removeListener("chainChanged", chainChanged);
  if (disconnected) eip1193Provider.removeListener("disconnect", disconnected);
}

export async function prepare1193Provider(
  eip1193Provider,
  addressOrIndex,
  chainId,
  { accountsChanged, chainChanged, disconnected }
) {
  let request;
  // Get the eip 1193 compatible request method
  if (eip1193Provider.request) {
    request = eip1193Provider.request.bind(eip1193Provider);
  } else if (eip1193Provider.send) {
    // This is the ethers JsonRpcProvider api which predated eip 1193 and this package is made *for* ethers
    request = (r) => eip1193Provider.send(r.method, r.params || []);
  }
  if (!request) {
    throw new Error(
      `EIP 1193 compatible providers must implement one of 'request' or 'send'`
    );
  }

  // Ensure we always remove, though I believe this un-necessary
  removeListeners(eip1193Provider, {
    accountsChanged,
    chainChanged,
    disconnected,
  });
  let accounts;
  try {
    accounts = await request({ method: "eth_requestAccounts" });
  } catch (err) {
    log.info(
      `eth_requestAccounts not available on provider ${eip1193Provider.constructor.name}`
    );
  }

  if (isUndefined(addressOrIndex)) {
    if (Array.isArray(accounts) && accounts.length) {
      addressOrIndex = accounts[0];
    }
  } else if (typeof addressOrIndex === "number") {
    if (Array.isArray(accounts) && accounts.length) {
      addressOrIndex = accounts[addressOrIndex];
    }
  }

  if (eip1193Provider.on) {
    // TODO handle disconnect/connect events
    if (accountsChanged) eip1193Provider.on("accountsChanged", accountsChanged);
    if (chainChanged) eip1193Provider.on("chainChanged", chainChanged);
    if (disconnected) eip1193Provider.on("disconnect", disconnected);
  }

  if (!chainId) {
    // chainId = alwaysNumber((await provider.getNetwork()).chainId);
    try {
      const r = await request({ method: "eth_chainId" });
      chainId = alwaysNumber(r);
    } catch (err) {
      log.info(`failed to get chainId`, etherrmsg(err));
    }
  } else {
    let currentChainId;
    try {
      const r = await request({ method: "eth_chainId" });
      currentChainId = alwaysNumber(r);
    } catch (err) {
      log.info(`failed to check chainId`, etherrmsg(err));
    }

    if (chainId != currentChainId) {
      throw new Error(
        `chain id mis match. expected ${chainId}, have ${currentChainId}`
      );
    }
  }

  return {
    evmProviderType: eip1193Provider?.constructor?.name,
    provider: eip1193Provider,
    request: request,
    accounts,
    addressOrIndex,
    chainId,
  };
}

const alwaysNumber = (n) => (ethers.utils.isHexString(n) ? parseInt(n, 16) : n);

const getGlobalObject = () => {
  if (typeof globalThis !== "undefined") {
    return globalThis;
  }
  if (typeof self !== "undefined") {
    return self;
  }
  if (typeof window !== "undefined") {
    return window;
  }
  if (typeof global !== "undefined") {
    return global;
  }
  throw new Error("[svelte-ethers-store] cannot find the global object");
};

export function getWindowEthereum() {
  try {
    if (getGlobalObject().ethereum) return getGlobalObject().ethereum;
  } catch (err) {
    log.error("no globalThis.ethereum object");
  }
}
