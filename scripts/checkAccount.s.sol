// PDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./constants.sol";
import {EIP6551_REGISTRY} from "src/constant.sol";

import {console} from "forge-std/Script.sol";
import {ActionScriptBase} from "./ActionScriptBase.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

contract CheckAccountScript is ActionScriptBase {

    address tugawarAddr;
    address boundAddr;
    address implAddr;

    function help() public view {
      console.log("-s env() | -s checkimp()");
    }
    function run() public {

      _env(false);
      checkimp();
    }

    function accgame() public {
      bytes memory accountCall = abi.encodeWithSignature("getGameByAccount(address account)", boundAddr);
      ERC6551Account account = ERC6551Account(payable(boundAddr));
      account.execute(payable(tugawarAddr), 0, accountCall, 0);
    }

    function checkimp() public view {

      if (!ERC6551AccountLib.isERC6551Account(
        boundAddr, implAddr, EIP6551_REGISTRY)) {
        console.log("failed: %x is not implemented by %x", boundAddr, implAddr);
        return;
      }
      console.log("ok: %x is implemented by %x", boundAddr, implAddr);
    }

    function env() public {
      _env(true);
    }

    function _env(bool show) public {

      // !NOTE: That env file parsing in foundry is super senstive to syntax errors
      // - miss a 0x prefix and the key wont be available to envUint
      // - make a // comment instead of a # bash style and the whole env will
      //   be missing

      tugawarAddr = vm.envOr("TUGAWAR_ADDR", LAST_KNOWN_TUGAWAR_ADDR);
      boundAddr = vm.envOr("BOUND", vm.envOr("POLYZONE_BOUND", address(0)));
      implAddr = vm.envOr("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS", vm.envOr("IMPL_ADDR", LAST_KNOWN_IMPLEMENTATION_ADDR));
      if (!show)
        return;

      console.log("TUGAWAR_ADDR: %x", tugawarAddr);
      console.log("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS", address(0));
      console.log("IMPL_ADDR: %x", implAddr);
      console.log("BOUND: %x", boundAddr);
    }
}
