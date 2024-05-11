import * as env from '$env/static/public';
/** @type {import('./$types').PageLoad} */
export function load({params, url, route}) {
  return {
    arenaAddress:{
      "redstone": env['PUBLIC_REDSTONE_TUGAWAR_ADDR'] ?? '',
      "local": env['PUBLIC_LOCAL_TUGAWAR_ADDR'] ?? '',
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
