import * as env from '$env/static/public';
import { env as secrets } from '$env/dynamic/private';
import { json } from '$lib/server/request.js';

export function GET() {
  const chainId = Number(env['PUBLIC_REDSTONE_CHAINID']);
  let chainIdHex = chainId.toString(16);
  // 0x prefixed, but not padded is the required native format
  chainIdHex = '0x' + chainIdHex;

  const chain = {
    name: 'redstone',
    description: 'Redstone',
    chainConfig: {
      chainId: chainIdHex,
      // chainId,
      chainNamespace: 'eip155'
    },
    currency: 'ETH',
    chainId: chainId,
    polling: env['PUBLIC_REDSTONE_POLLING'] ?? 2000,
    arenaProxy: env['PUBLIC_REDSTONE_TUGAWAR_ADDRESS'],
    arenaDeployer: env['PUBLIC_REDSTONE_TUGAWAR_DEPLOYER'],

  };
  if (secrets['REDSTONE_URL'])
    chain.url = secrets['REDSTONE_URL'];
  if (!chain.url && env['PUBLIC_REDSTONE_URL'])
    chain.url = env['PUBLIC_REDSTONE_URL'];
  if (chain.url)
    chain.chainConfig.rpcTarget = chain.url;
  if (env['PUBLIC_REDSTONE_BRIDGE'])
    chain.bridge = env['PUBLIC_REDSTONE_BRIDGE'];
  if (env['PUBLIC_REDSTONE_ETHERSCAN_URL']) {
    chain.etherscanUrl = env['PUBLIC_REDSTONE_ETHERSCAN_URL'];
    chain.chainConfig.blockExplorerUrl = chain.etherscanUrl;
  }

  if (env['PUBLIC_REDSTONE_ZERODEV_PROJECT_ID']) {
    chain.zeroDevProjectId = env['PUBLIC_REDSTONE_ZERODEV_PROJECT_ID'];
    chain.bundlerUrl = env['PUBLIC_REDSTONE_BUNDLER_URL'];
    chain.payMasterUrl = env['PUBLIC_REDSTONE_PAYMASTER_URL'];
  }

  return json(chain);
}
