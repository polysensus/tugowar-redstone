
export async function fetchChainConfigUrl(url, {fetch}) {
  let chain = url.searchParams.get("chain");
  if (!chain)
    throw error(404, {message: `chain is a required query parameter`});

  return await fetchChainConfig(chain, {fetch});
}

export async function fetchChainConfig(chain, {fetch}) {

  let resp = await fetch(`/api/chains/${chain}`);
  if (!resp.ok)
    throw error(resp.status, {message: `fetching chain config ${chain}`});

  return await resp.json();
}
