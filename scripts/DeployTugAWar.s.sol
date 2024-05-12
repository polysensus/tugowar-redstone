// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Script.sol";
import {DeployScriptBase} from "./DeployScriptBase.sol";
import {TugAWar} from "src/TugAWar.sol";

contract DeployTugAWarScript is DeployScriptBase {
  function run() public {
    startBroadcast();
    _run();
    vm.stopBroadcast();
  }

  function _run() public {

    address [] memory allowedTokens = new address[](2);
    allowedTokens[0] = vm.envAddress("DS_ZONE_ADDR");
    allowedTokens[1] = vm.envAddress("DS_TOKEN_ADDR");
    TugAWar taw = new TugAWar(
      allowedTokens,
      vm.envAddress("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS"));
    console.log(address(taw));
  }
}

