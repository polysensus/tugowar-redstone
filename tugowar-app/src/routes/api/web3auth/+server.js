import * as env from '$env/static/public';
// import { env as secrets } from '$env/dynamic/private';
import { json } from '$lib/server/request.js';

/** @type {import('./arena/$types').RequestHandler} */
export function GET() {
  return json({
    // web3auth - https://web3auth.io/docs/sdk/web/modal/initialize
    clientId: env['PUBLIC_WEB3AUTH_CLIENT_ID'],
    web3AuthNetwork: env['PUBLIC_WEB3AUTH_NETWORK'],
    adapterSettings: {
      enableMetamask: true,
      openlogin:{
        adapterSettings:{
          // "popup" works on desctop, "redirect" works for iPad, iPhone and phones in general
          uxMode: "redirect"
        }
      }
    }
  });
}
