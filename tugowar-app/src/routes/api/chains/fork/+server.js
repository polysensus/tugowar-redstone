import * as env from '$env/static/public';
import { env as secrets } from '$env/dynamic/private';
import { json } from '$lib/server/request.js';

/** @type {import('./arena/$types').RequestHandler} */
export function GET() {

  // WARNING: ASSUMES FORKED anvil instance
  const chainId = Number(env['PUBLIC_FORK_CHAINID']);
  let chainIdHex = chainId.toString(16);
  // 0x prefixed, but not padded is the required native format
  chainIdHex = '0x' + chainIdHex;

  const chain = {
    name: 'fork',
    description: 'For testing against a forked chain, currently redstone',
    chainConfig: {
      chainId: chainIdHex,
      chainNamespace: 'eip155'
    },
    chainId: chainId,
    currency: 'ETH',
    url: secrets['PUBLIC_FORK_URL'] ?? 'http://127.0.0.1:8545',
    polling: env['PUBLIC_FORK_POLLING'] ?? 800,
  } 
  if (env['PUBLIC_FORK_TUGAWAR_ADDR'])
    chain.arenaProxy = env['PUBLIC_FORK_TUGAWAR_ADDR'];
  if (env['PUBLIC_FORK_TUGAWAR_DEPLOYER'])
    chain.arenaDeployer = env['PUBLIC_FORK_TUGAWAR_DEPLOYER'];
  if (env['PUBLIC_FORK_DS_ZONE_ADDR'])
    chain.dsZoneAddr = env['PUBLIC_FORK_DS_ZONE_ADDR'];
  if (env['PUBLIC_ZONE_DS_TOKEN_ADDR'])
    chain.dsTokenAddr = env['PUBLIC_ZONE_DS_TOKEN_ADDR'];
  if (env['PUBLIC_ZONE_DS_GAME_ADDR'])
    chain.dsTokenAddr = env['PUBLIC_ZONE_DS_GAME_ADDR'];

  if (chain.url)
    chain.chainConfig.rpcTarget = chain.url;
  if (env['PUBLIC_FORK_BRIDGE'])
    chain.bridge = env['PUBLIC_FORK_BRIDGE'];
  if (env['PUBLIC_FORK_ETHERSCAN_URL']) {
    chain.etherscanUrl = env['PUBLIC_FORK_ETHERSCAN_URL'];
    chain.chainConfig.blockExplorerUrl = chain.etherscanUrl;
  }

  if (env['PUBLIC_FORK_ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS'])
    chain.accImpl = env['PUBLIC_FORK_ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS'];
  if (env['PUBLIC_FORK_ERC6551_ACCOUNT_SALT'])
    chain.accSalt = env['PUBLIC_FORK_ERC6551_ACCOUNT_SALT'];

  if (env['PUBLIC_REDSTONE_ZERODEV_PROJECT_ID']) {
    chain.zeroDevProjectId = env['PUBLIC_REDSTONE_ZERODEV_PROJECT_ID'];
    chain.bundlerUrl = env['PUBLIC_REDSTONE_BUNDLER_URL'];
    chain.payMasterUrl = env['PUBLIC_REDSTONE_PAYMASTER_URL'];
  }

  console.log(JSON.stringify(chain));

  return json(chain);
}
