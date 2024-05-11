import { ProviderType } from '$lib/chainkit/providertypes.js';
import { all } from '$lib/chains/supportedproviders.js';

import { json } from '$lib/server/request.js';

export async function GET({fetch, request}) {

  const url = new URL(request.url);
  /** @type {string|string[]}*/
  let types = url.searchParams.get("types");
  if (!types)
    types = `${ProviderType.NamedRPC},${ProviderType.Hardhat}`;
  types = types.split(",");

  const result = [];

  for (const provider of Object.values(all)) {
    if (!types.includes(provider.type))
      continue
    // if (!provider.fetch) {
    //   result.push(provider);
    //   continue
    // }
    let resp = await fetch(`/api/chains/${provider.name}`)
    const chain = await resp.json();
    result.push(chain);
  }

  return json(result);
}