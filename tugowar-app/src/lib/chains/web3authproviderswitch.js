// --- lib deps
import * as web3auth_modal from '@web3auth/modal';
import * as web3auth_base from '@web3auth/base';
const { Web3Auth } = web3auth_modal;
const { ADAPTER_STATUS } = web3auth_base;
import * as web3auth_openlogin_adapter from '@web3auth/openlogin-adapter';
const { OpenloginAdapter } = web3auth_openlogin_adapter;
import * as web3auth_methmask_adapter from '@web3auth/metamask-adapter';
const {MetamaskAdapter} = web3auth_methmask_adapter;

// @ts-ignore

import { Web3AuthModalProviderSwitchAbstract } from '../chainkit/web3authmodalproviderswitch.js';

/**
 * Web3ModalProviderSwitch adds support for cfg.type.startsWith('web3auth')
 * It deals with the fact that Web3Modal must be instanced as a singleton
 */
export class Web3AuthModalProviderSwitch extends Web3AuthModalProviderSwitchAbstract {
  newWeb3Auth(cfg) {
    return new Web3Auth(cfg);
  }

  /**
   * newOpenloginAdapter instantiages a web3auth/openlogin-adapter instance
   * with the provided adapterSettings
   * @param {object} cfg
   * @param {object} adapterSettings
   */
  newOpenLoginAdapter(cfg, adapterSettings) {
    // cfg is ignored, we assume that it contains clientId and network
    return new OpenloginAdapter(adapterSettings);
  }
  newMetamaskAdapter(cfg, adapterSettings) {
    return new MetamaskAdapter(adapterSettings);
  }
  /**
   * Call after init to determine the current status
   *
   * Useful for initializing logged in / connected states without triggering
   * modal
   */
  async refreshLoginStatus(selectIfConnected = false) {
    const status = super.refreshLoginStatus(ADAPTER_STATUS.CONNECTED);
    if (!status) return undefined;

    let connectedName;

    for (const [name, chainConfig] of Object.entries(this.web3authChains)) {
      if (chainConfig.chainId !== this.web3auth.coreOptions.chainConfig.chainId) continue;

      console.log(`Web3AuthModalProviderSwitch# auto selecting ${name}`);
      connectedName = name;
      if (selectIfConnected) await this.select(connectedName);
      break;
    }

    return connectedName;
  }
}
