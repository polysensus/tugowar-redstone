// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

contract ActionScriptBase is Script {

  function startBroadcast(string memory keyName) internal {
    // If keyName is not set, the script is assumed to be run with --ledger
    uint256 key = vm.envOr(keyName, uint256(0));
    if (key != 0)
      vm.startBroadcast(key);
    else
      vm.startBroadcast();
  }

  function startBroadcastPub(string memory keyName) internal {
    // If keyName is not set, the script is assumed to be run with --ledger
    address key = vm.envOr(keyName, address(0));
    if (key != address(0))
      vm.startBroadcast(key);
    else
      vm.startBroadcast();
  }
}
