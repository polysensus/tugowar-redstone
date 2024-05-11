/**
 * Abstract implementation of a ProviderSwitch for Web3Auth
 * Expected use is to inherit and implement newWeb3Auth with just  "return new Web3Auth(cfg)"
 */

// --- lib deps
import { ethers } from "ethers";
import * as pkg from "@web3auth/ethereum-provider";
const { EthereumPrivateKeyProvider } = pkg;

import { getLogger } from "../log.js";

import { awaitable, isFunction } from "../idioms.js";
// @ts-ignore
import { ProviderSwitch } from "./providercontexts.js";

const log = getLogger("web3authproviderswitch");

/**
 * Web3ModalProviderSwitch adds support for cfg.type.startsWith('web3auth')
 * It deals with the fact that Web3Modal must be instanced as a singleton
 */
export class Web3AuthModalProviderSwitchAbstract extends ProviderSwitch {
  constructor(cfg = {}) {
    super(cfg);

    this.web3authOptions = undefined;
    this._promisedWeb3Auth = undefined;
    this.web3auth = undefined;
    this.web3authChains = {};
    this.modalOpen = false;
    this.loggedIn = false;
    this.web3AuthProvider = undefined;

    const { authenticated } = cfg;

    this.authenticated = (state) => {
      log.info(`Web3ModalProviderSwitch#authenticated ${state}`);
      if (!authenticated) return;
      try {
        return authenticated(state);
      } catch (err) {
        log.info(`ERROR: Web3ModalProviderSwitch#authenticated ${err}`);
      }
    };
  }

  /** Avoid forcing the dependency choice in this package, and also make this completely mockable */
  newWeb3Auth(cfg) {
    throw new Error(
      `ERROR: ${this.constuctor.name} this class must be extended to provide this method`
    );
  }

  async select(name) {
    const newCtx = this.requireContext(name);
    this.stopCurrent();

    const chainConfig = this.web3authChains[name];
    let chainId = chainConfig?.chainId;
    if (!chainId) {
      log.info(
        `Web3ModalProviderSwitch#select: selecting non web3auth provider config ${name}`
      );
      await newCtx.resume(this);
      this.current = name;
      return newCtx;
    }
    chainId = ethers.utils.hexlify(chainId);

    log.info(`Web3ModalProviderSwitch#select: selecting ${name} ${chainId}`);
    if (!this.isLoggedIn()) {
      await this.login();
    }

    // addChain is defered until this point because it requires a logged in
    // modal. And we don't want to trigger login on page load (when the
    // providers are initialy discovered).
    if (chainConfig.addPending) {
      delete chainConfig.addPending;
      try {
        await this.web3auth.addChain(chainConfig);
      } catch (err) {
        chainConfig.addPending = true;
        log.info(`ERROR:Web3ModalProviderSwitch#select: addChain ${err}`);
        return;
      }
    }

    await this.web3auth.switchChain({ chainId });
    const provider = new ethers.providers.Web3Provider(this.web3auth.provider);
    await newCtx.setProvider(provider);
    const address = await provider.getSigner()?.getAddress();
    this.current = name;
    log.info(
      `Web3ModalProviderSwitch#select: provider signerAddress ${address} ${
        this.current
      } ${this.getCurrent()}`
    );
  }

  isLoggedIn() {
    return this.loggedIn;
  }

  refreshLoginStatus(adapterStatusConnected) {
    const apply = (state, msg) => {
      if (this.loggedIn === state) return;
      this.loggedIn = state;
      this.authenticated(this.loggedIn);
      if (msg) console.log(msg);
      return state;
    };
    const was = this.loggedIn;
    if (!this.web3auth?.connectedAdapterName)
      return apply(false, "no adapter name");
    if (this.web3auth.status !== adapterStatusConnected)
      return apply(false, `wrong status: ${this.web3auth.status}`);
    if (!this.web3auth.provider) return apply(false, "no provider");
    return apply(true, "refreshed connected");
  }

  async login(force) {
    if (this.modalOpen) {
      log.info(`Web3ModalProviderSwitch#login modal is already open`);
      return;
    }
    if (!this.web3auth) {
      log.info(`Web3ModalProviderSwitch#login modal instance is undefined`);
      return;
    }
    if (this.loggedIn && !force) {
      log.info(`Web3ModalProviderSwitch#login already logged in`);
      return;
    }
    try {
      this.modalOpen = true;
      console.log("*** calling connect ***");
      await this.web3auth.connect();
      this.loggedIn = true;
      this.authenticated(this.loggedIn);
    } catch (err) {
      log.info(
        `ERROR: Web3ModalProviderSwitch#login - calling connect: ${JSON.stringify(
          err
        )}, ${err}`
      );
    }
    this.modalOpen = false;
  }

  logout() {
    if (!this.web3auth) {
      log.info(`no web3auth modal instance to do logout with`);
      return;
    }
    this.web3auth.logout();
    this.loggedIn = false;
    this.authenticated(this.loggedIn);
    log.info(`Web3AuthModalProviderContext#logout ok`);
  }

  /**
   * Ensures there is only one call to initModal, whilst allowing most of the provider configration to happenin paralalel
   */
  async initSingletonWeb3Auth(chainConfig) {
    if (this.web3auth) return false;

    let creator = false;
    if (!this._promisedWeb3Auth) {
      creator = true;
      // This is async, but we will have multiple waiters
      this._promisedWeb3Auth = this._initWeb3Auth(chainConfig);
    }

    try {
      await this._promisedWeb3Auth;
      // <-- re-entrancy can happen after this point
    } catch (err) {
      log.debug(
        `ERROR: Web3ModalProviderSwitch#initSingletoneWeb3Auth: await this._promisedWeb3Auth ${err}`
      );
    }
    if (creator) {
      delete this._promisedWeb3Auth;
    }
    // guarantee all callers that the instance is available on return
    if (!this.web3auth)
      throw new Error(
        `ERROR: Web3ModalProviderSwitch#initSingletonWeb3Auth promised web3auth instance missing`
      );

    return creator;
  }

  /**
   * DO NOT call directly, see initSingletonWeb3Auth
   * @param {*} chainConfig
   * @returns
   */
  async _initWeb3Auth(chainConfig) {
    if (this.web3auth) return;

    log.info(
      `Web3ModalProviderSwitch#_initWeb3Auth: creating Web3Auth and calling initModal for ${chainConfig.chainId}`
    );
    if (isFunction(this.web3authOptions))
      this.web3authOptions = this.web3authOptions();

    // allow for functions returning promises.
    if (awaitable(this.web3authOptions))
      this.web3authOptions = await this.web3authOptions();

    if (
      !this.web3authOptions?.clientId ||
      !this.web3authOptions?.web3AuthNetwork
    )
      throw new Error(
        `clientId and web3AuthNetwork must be present on the web3auth options: have "${Object.keys(
          this.web3authOptions
        )}"`
      );

    log.info(
      `Web3ModalProviderSwitch#_initWeb3Auth: web3authOptions: ${JSON.stringify(
        this.web3authOptions
      )}`
    );

    if (this.web3authOptions.adapterSettings) {
      this.web3AuthAdapterSettings = this.web3authOptions.adapterSettings;
      delete this.web3authOptions.adapterSettings;
    }

    let privateKeyProvider;
    try {
      log.info(`Web3ModalProviderSwitch#_initWeb3Auth: CALL new EthereumPrivateKeyProvider`);
      privateKeyProvider = new EthereumPrivateKeyProvider({
        config: { chainConfig }
      });
    } catch (err) {
      log.info(`Web3ModalProviderSwitch#_initWeb3Auth: new EthereumPrivateKeyProvider ERROR: ${err}`);
      throw new Error(err);
    }
    log.info(`Web3ModalProviderSwitch#_initWeb3Auth: new EthereumPrivateKeyProvider OK`);

    let web3auth;
    try {
      log.info(`Web3ModalProviderSwitch#_initWeb3Auth: CALL newWeb3Auth`);
      web3auth = this.newWeb3Auth({
        ...this.web3authOptions, privateKeyProvider,
      });
    } catch (err) {
      log.info(`Web3ModalProviderSwitch#_initWeb3Auth: newWeb3Auth ERROR: ${err}`);
      throw new Error(err);
    }
    log.info(`Web3ModalProviderSwitch#_initWeb3Auth: newWeb3Auth ok: ${web3auth}`);
    if (this.web3AuthAdapterSettings?.openlogin !== undefined) {
      const adapterSettings = this.web3AuthAdapterSettings.openlogin;
      log.info(
        `Web3ModalProviderSwitch#_initWeb3Auth: configuring adapter: ${JSON.stringify(
          adapterSettings
        )}`
      );
      const adapter = this.newOpenLoginAdapter(
        { ...this.web3authOptions, chainConfig },
        adapterSettings
      );
      log.info(`Web3ModalProviderSwitch#_initWeb3Auth: newOpenLoginAdapter ok`);
      web3auth.configureAdapter(adapter);
      log.info(`Web3ModalProviderSwitch#_initWeb3Auth: configureAdapter ok`);
    } else {
      log.info(
        `Web3ModalProviderSwitch#_initWeb3Auth: no adapter specialisations provided`
      );
    }

    if (this.web3AuthAdapterSettings?.enableMetamask) {

      const adapterSettings = this.web3AuthAdapterSettings.metamask;
      log.info(
        `Web3ModalProviderSwitch#_initWeb3Auth: configuring metamask adapter: ${JSON.stringify(
          adapterSettings
        )}`
      );
      const adapter = this.newMetamaskAdapter(
        { ...this.web3authOptions, chainConfig },
        adapterSettings
      );
      log.info(`Web3ModalProviderSwitch#_initWeb3Auth: newMetamaskAdapter ok`);
      web3auth.configureAdapter(adapter);
      log.info(`Web3ModalProviderSwitch#_initWeb3Auth: configureAdapter ok`);
    }
    await web3auth.initModal();
    log.info(`Web3ModalProviderSwitch#_initWeb3Auth: initModal ok`);
    this.web3auth = web3auth;
  }

  /** Impotently add a network configuration. If the configuration provides a
   * web3auth chainConfig with at least chainSpace set, the network is added to
   * the Web3Modal instance. The first such configuration triggers instantiation
   * and initModal for Web3Auth. */
  async addNetwork(cfg) {
    if (!cfg.chainConfig?.chainNamespace) {
      log.debug(
        `Web3ModalProviderSwitch#addNetwork: ${cfg.name} is not configured for web3auth (no chainSpace set)`
      );
      return;
    }

    log.info(
      `Web3ModalProviderSwitch#addNetwork: considering config ${cfg.name}`
    );
    if (this.web3authChains[cfg.name]) {
      log.info(`Web3ModalProviderSwitch#addNetwork: ${cfg.name} already known`);
      return;
    }

    const chainConfig = {
      chainId: ethers.utils.hexlify(cfg.chainId),
      chainNamespace: cfg.chainConfig.chainNamespace,
      displayName: cfg.description,
      rpcTarget: cfg.url,
      ticker: cfg.currency,
      tickerName: cfg.currency,
      ...cfg.chainConfig, // allow it to override the defaults from the primary config.
    };
    log.info("----------");
    log.info("web3auth chainConfig");
    log.info(JSON.stringify(chainConfig, null, "  "));
    log.info("----------");

    const creator = await this.initSingletonWeb3Auth(
      chainConfig,
      cfg.adapterSettings
    );
    if (creator) {
      // IF this call created then the chainConfig does not need to be added, it was provided to the constructor.
      log.info(
        `Web3ModalProviderSwitch#addNetwork: initModal complete for ${cfg.name}`
      );
      this.web3authChains[cfg.name] = chainConfig;
      log.debug(
        `Web3ModalProviderSwitch#addNetwork: initial network for web3auth ${cfg.name}`
      );
      return;
    }

    log.info(
      `Web3ModalProviderSwitch#addNetwork: adding chain ${cfg.name} ${chainConfig.chainId} to web3auth for ${cfg.name}`
    );
    // await this.web3auth.addChain(chainConfig);
    chainConfig.addPending = true;
    this.web3authChains[cfg.name] = chainConfig;
    log.debug(
      `Web3ModalProviderSwitch#addNetwork: added network to web3auth for ${cfg.name}`
    );
  }

  /**
   * Note that opts must include a callback which delivers a valid web3auth config
   * See: Web3AuthOptions here https://web3auth.io/docs/sdk/web/modal/initialize
   *      Only a chainId and chainNamespace are required. The other options are provider/chain specific.
   * @param {*} cfgs
   * @param {*} contextfactory
   * @param {*} opts
   * @returns
   */
  async prepare(cfgs, contextfactory, opts) {
    const { web3authOptions } = opts;

    this.web3authOptions = web3authOptions;
    return super.prepare(cfgs, contextfactory, opts);
  }
}
