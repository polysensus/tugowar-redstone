
import {ethers} from 'ethers';
import { error } from '@sveltejs/kit';
import * as env from '$env/static/public';
// import { env as secrets } from '$env/dynamic/private';
import { json, requireParam } from '$lib/server/request.js';

//import accountSol from "$lib/abi/ERC6551Account.json";
import registrySol from "$lib/abi/IERC6551Registry.json";

const registryAddress = env['PUBLIC_ERC6551_REGISTRY'] ?? '0x000000006551c19487814612e58FE06813775758';

export async function GET({fetch, request}) {

  const url = new URL(request.url);

  const chainConfig = requireParam(url, "chain");
  const tokenId = requireParam(url, "tokenid");

  let resp = await fetch(`/api/chains/${chainConfig}`);
  if (!resp.ok)
    throw error(resp.status, {message: `fetching chain config ${chainConfig}`});

  /** @type {{url:string,arenaProxy:string}} */
  const chain = await resp.json();

  console.log(JSON.stringify(chain));
  // const provider = new ethers.providers.StaticJsonRpcProvider(chain.url);
  const provider = new ethers.providers.StaticJsonRpcProvider(chain.url);

  const registry = new ethers.Contract(registryAddress, registrySol.abi, provider);

  // const tugawar = chain.arenaProxy; // for reasons of copy pasta
  const dsZoneAddr = chain.dsZoneAddr;
  const accSalt = ethers.utils.formatBytes32String(chain.accSalt);
  // TODO: DS 1155
  console.log(`account(${chain.accImpl},${accSalt},${chain.chainId},${dsZoneAddr},${tokenId})`);
  const bound = await registry.account(chain.accImpl, accSalt, chain.chainId, dsZoneAddr, tokenId);
  console.log(`bound: ${bound}`);

  return json({bound, token:dsZoneAddr, tokenId, is1155: false });
}
