// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Script.sol";
import {ActionScriptBase} from "./ActionScriptBase.sol";
import {TugAWar} from "src/TugAWar.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";

contract JoinSideScript is ActionScriptBase {

    TugAWar public taw;

    function run() public {

      startBroadcast(vm.envOr("KEYNAME", string("POLYZONE_KEY")));
      _run();
      vm.stopBroadcast();
    }

    function _run() public {

      address TUGAWAR = vm.envAddress("TUGAWAR_ADDR");
      taw = TugAWar(TUGAWAR);

      address boundAddr = vm.envOr("BOUND", vm.envOr("POLYZONE_BOUND", address(0)));
      uint256 preferredOrZero = vm.envOr("SIDE", uint256(0));

      bytes memory joinSideCall = abi.encodeWithSignature("joinSide(uint256)", preferredOrZero);
      ERC6551Account account = ERC6551Account(payable(boundAddr));
      account.execute(payable(address(taw)), 0, joinSideCall, 0);
    }
}
