import { ProviderType } from '../chainkit/providertypes.js';

import { writable, derived, get } from 'svelte/store';

import { Web3AuthModalProviderSwitch } from './web3authproviderswitch.js';

import { FetchProviderContext } from './fetchprovidercontext.js';
import { Web3AuthModalProviderContext } from './web3authprovidercontext.js';

/**
 * ChainPresence is the 'login' context.
 *
 * ChainPresence manages a provider context for a chain account owner
 * interactions with chains.  So, for example,  the holder of one or more wallet
 * private keys can connect to the appropriate chain and issue transactions with
 * that key. This is mediated through one of the supported provider types
 * available for the specific chain.
 *
 */
export class ChainPresence {
  static async create(cfg) {
    const presence = new ChainPresence(cfg);
    await presence.refreshProviders();
    return presence;
  }

  constructor(cfg) {

    this.cfg = cfg;
    this.cfg.excludeNetworkTypes = [ProviderType.APIProxyRPC, ProviderType.NamedRPC, ProviderType.EthersRPC];

    this.providerCtx = undefined;
    this.authenticated = writable(false);
    this.providerName = writable(undefined);

    // provider selection
    this.providerSwitch = new Web3AuthModalProviderSwitch({
      prepared: (name, ctx) => {
        // this.providerName.set(name);    
        console.log(`prepapred: ${name}`);
      },
      accountsChanged: async (name, ctx) => this.accountsChanged(name, ctx),
      chainChanged: async (name, ctx) => this.chainChanged(name, ctx),
      disconnected: async (name, ctx) => this.disconnected(name, ctx),
      authenticated: (authenticated) => this.authenticated.set(authenticated)
    });

  }
  logout() {
    if (!get(this.authenticated)) return;
    this.providerSwitch.logout();
  }

  /**
   * 
   * @param {string} providerName 
   * @returns 
   */
  async selectProvider(providerName) {
    if (!providerName) {
      console.info(`clearing provider selection`);
      this.providerCtx = undefined;
      return;
    }

    // Prioritize the provider selection
    if (providerName == get(this.providerName)) {
      return;
    }

    try {
      this.providerCtx = await this.providerSwitch.select(providerName);
    } catch (err) {
      console.info(`failed to select provider ${providerName} ${err}`);
      return;
    }
  }
  async accountsChanged(name, ctx) {
    console.debug('accountsChanged');
  }

  async chainChanged(name, ctx) {
    console.debug('accountsChanged', name);
  }

  async disconnected(name, ctx) {
    console.debug('disconnected', name);
  }

  async refreshProviders() {
    const web3authOptions = async () => {
      const resp = await fetch(`/api/web3auth/`);
      const web3auth = await resp.json();
      if (web3auth?.error) {
        const error = JSON.stringify(web3auth.error);
        console.info(`error fetching web3auth options ${error}`);
        throw new Error(error);
      }
      console.log(`ChainPresence# refreshProviders api/web3auth: ${JSON.stringify(web3auth)}`);
      return web3auth;
    };
    const networks = {};
    for (const cfg of Object.values(this.cfg.networks)) {

      cfg.id = cfg.id ?? cfg.name;

      if (this.cfg.excludeNetworkTypes.includes(cfg.type))
        continue;

      // make the first id the same as the name, so we only get -{n} suffices on
      // providers we explicitly configure that way.
      networks[cfg.id] = cfg;

      if (cfg.name !== 'local' || (this.cfg.hardhatWalletCount ?? 0) < 1)
        continue

      console.log(`adding ${this.cfg.hardhatWalletCount - 1} hardhat wallets`)
      let first = this.cfg.hardhatWalletFirst ?? 1;
      // remember addressOrIndex defaults to 0 so we automatically get at least one
      for (let i=0; i < this.cfg.hardhatWalletCount - 1; i++) {
        const hhCfg = {...cfg}
        hhCfg.id = `${cfg.name}/${first+i}`;
        hhCfg.addressOrIndex = first+i;
        networks[hhCfg.id] = hhCfg;
      }
    }

    await this.providerSwitch.prepare(
      // this.cfg.networks,
      networks,
      (cfg) => {
        console.log(`preparing: ${cfg.name} ${cfg.id}`);
        if (cfg.type.startsWith('web3auth')) {
          return new Web3AuthModalProviderContext(cfg);
        }
        return new FetchProviderContext(cfg);
      },
      { fetch: true, web3authOptions }
    );

    return Object.values(this.providerSwitch.available).map((ctx) => ctx.cfg);
  }
}
