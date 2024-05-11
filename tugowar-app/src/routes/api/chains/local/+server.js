import * as env from '$env/static/public';
import { env as secrets } from '$env/dynamic/private';
import { json } from '$lib/server/request.js';

/** @type {import('./arena/$types').RequestHandler} */
export function GET() {

  const chain = {
    name: 'local',
    description: 'For testing against locally hosted chain end points',
    chainConfig: {
      chainNamespace: 'eip155'
    },
    // chainId: 31337, // hardhat
    chainId: 22300, // anvil
    currency: 'ETH',
    url: secrets['PUBLIC_LOCAL_URL'] ?? 'http://127.0.0.1:8545',
    polling: env['PUBLIC_LOCAL_POLLING'] ?? 800,
  } 
  if (env['PUBLIC_LOCAL_TUGAWAR_ADDRESS'])
    chain.arenaProxy = env['PUBLIC_LOCAL_TUGAWAR_ADDRESS'];
  if (env['PUBLIC_LOCAL_TUGAWAR_DEPLOYER'])
    chain.arenaDeployer = env['PUBLIC_LOCAL_TUGAWAR_DEPLOYER'];
  if (env['PUBLIC_LOCAL_DS_ZONE_ADDR'])
    chain.dsZoneAddress = env['PUBLIC_LOCAL_DS_ZONE_ADDR'];

  return json(chain);
}
