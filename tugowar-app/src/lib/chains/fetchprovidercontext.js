import { ProviderContext } from '../chainkit/providercontexts.js';

import { apiPath } from './api.js';

export class FetchProviderContext extends ProviderContext {
  async prepareProvider() {
    if (this.cfg.fetch) {
      const resp = await fetch(`${apiPath}${this.cfg.name}`);
      const remoteCfg = await resp.json();
      if (remoteCfg?.error) {
        const error = JSON.stringify(remoteCfg.error);
        throw new Error(error);
      }
      this.cfg = { ...this.cfg, ...remoteCfg };
    }
    return super.prepareProvider();
  }
}
