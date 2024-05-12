// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

import {ActionScriptBase} from "./ActionScriptBase.sol";

contract DeployScriptBase is ActionScriptBase {

  function startBroadcast() internal {
    startBroadcast("DEPLOY_KEY");
  }
  function startBroadcastPub() internal {
    startBroadcast("DEPLOY_PUB");
  }
}
