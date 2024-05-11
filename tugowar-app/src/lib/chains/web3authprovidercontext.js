import { ethers } from 'ethers';

import { ProviderContext } from '../chainkit/providercontexts.js';

import { apiPath } from './api.js';

export class Web3AuthModalProviderContext extends ProviderContext {
  constructor(cfg = {}) {
    super(cfg);
    this.modalOpen = false;
    this.web3auth = undefined;
    this.web3AuthProvider = undefined;
    this.loggedIn = false;
  }
  /**
   * For Web3 we start with a normal rpc provider. In resume, which is triggered
   * on select, we initiate the web3auth flow.
   * @returns
   */
  async prepareProvider(switcher) {
    if (!switcher)
      throw new Error(`the web3auth provider context requires access to the switcher here`);

    if (this.cfg.fetch) {
      const resp = await fetch(`${apiPath}${this.cfg.name}`);
      const remoteCfg = await resp.json();
      if (remoteCfg?.error) {
        const error = JSON.stringify(remoteCfg.error);
        throw new Error(error);
      }
      this.cfg = { ...this.cfg, ...remoteCfg };
    }
    await switcher.addNetwork(this.cfg);
    return this;
  }

  async resume(switcher) {
    if (!switcher)
      throw new Error(`the web3auth provider context requires access to the switcher here`);
    try {
      this.modalOpen = true;
      await this.web3auth.connect();
      this.loggedIn = true;
    } catch (err) {
      console.log(`ERROR: this.modal.connect: ${JSON.stringify(err)}, ${err}`);
    }
    this.modalOpen = false;
    const provider = new ethers.providers.Web3Provider(this.web3auth.provider);
    await this.setProvider(provider);
    const address = await provider.getSigner()?.getAddress();
    console.log(
      `
signerAddress: ${[address, this.signerAddress]},
this.modal signer: ${provider.getSigner().constructor.name},
provider: ${provider.constructor.name}`
    );
  }
}
