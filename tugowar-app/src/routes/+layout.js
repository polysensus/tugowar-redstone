import * as env from '$env/static/public';
/** @type {import('./$types').PageLoad} */
export function load({params, url, route}) {
  return {
    arenaAddress:{
      "redstone": env['PUBLIC_REDSTONE_TUGAWAR_ADDRESS'] ?? '',
      "op-garnet": env['PUBLIC_OP_GARNET_TUGAWAR_ADDRESS'] ?? '',
      "op-sepolia": env['PUBLIC_OP_SEPOLIA_TUGAWAR_ADDRESS'] ?? '',
      "local": env['PUBLIC_LOCAL_TUGAWAR_ADDRESS'] ?? '',
    },
    request: {
      href:url.href,
      origin:url.origin,
      hostname:url.hostname,
      route,
      params
    }
  }
}
