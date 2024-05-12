// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";
import {IERC6551LastExecutor} from "src/IERC6551LastExecutor.sol";
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

    bool ok = IERC165(accountImplementation).supportsInterface(type(IERC6551LastExecutor).interfaceId);
    if (!ok) revert('wtf');
    console.log(address(accountImplementation));
  }
}
