
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC6551Account} from "src/ERC6551Account.sol";
import {console} from "forge-std/Script.sol";
import {DeployScriptBase} from "./DeployScriptBase.sol";

contract DeployAccountImplScript is DeployScriptBase {

  function run() public {
    startBroadcast();
    _run();
    vm.stopBroadcast();
  }
  function _run() public {
    ERC6551Account accountImplementation = new ERC6551Account();
    console.log(address(accountImplementation));
  }
}
