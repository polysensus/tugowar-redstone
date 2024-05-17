// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ActionScriptBase} from "./ActionScriptBase.sol";

contract DeployScriptBase is ActionScriptBase {

  uint256 forkDeployKey;
  address forkDeployAddr;

  uint256 FORK_BLOCK;

  function startFork() internal {

    FORK_BLOCK = vm.envOr("FORK_BLOCK", uint256(0));
    createFork(FORK_BLOCK);
    (forkDeployAddr, forkDeployKey) = makeAddrAndKey("FORK_DEPLOY_KEY");
    vm.deal(forkDeployAddr, 1 << 128);
    vm.startPrank(forkDeployAddr);
  }

  function startBroadcast() internal {
    startBroadcast("DEPLOY_KEY");
  }
  function startBroadcastPub() internal {
    startBroadcast("DEPLOY_PUB");
  }
}
