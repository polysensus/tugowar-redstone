// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Script.sol";
import {ActionScriptBase} from "./ActionScriptBase.sol";
import {TugAWar} from "src/TugAWar.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";
import "./constants.sol";

contract JoinSideScript is ActionScriptBase {

    function help() public view {
      console.log("-s run() | -s runforked() | -s test() | -s env() | -s testenv()");
    }

    string keyName;
    address tugawarAddr;
    address holderPub;
    address boundAddr;
    uint256 side;

    uint256 key;

    function run() public {

      _env(false);
      _envSecret(false);

      startBroadcast(keyName);
      _run();
      vm.stopBroadcast();
    }
    function runforked() public {
      console.log("rpc: %s", vm.rpcUrl("rpc"));
      _env(false);
      // startFork();
      createFork();
      vm.deal(holderPub, 1 << 128);
      vm.startPrank(holderPub);
      console.log("sender: %x", holderPub);

      _run();
      /*
      // vm.stopPrank();

      bytes memory accountCall;
      bytes memory result;
      ERC6551Account account = ERC6551Account(payable(boundAddr));

      accountCall = abi.encodeWithSignature("getGameByAccount(address)", boundAddr);
      result = account.execute(payable(tugawarAddr), 0, accountCall, 0);
      uint256 gid; uint256 duration; uint256 pulls; uint256 gotSide; uint256 tokenId; uint256 marker;
      (
        gid, duration, pulls, gotSide, tokenId, marker
      ) = abi.decode(result, (uint256, uint256, uint256, uint256, uint256, uint256));

      console.log("gid: %d, duration: %d, pulls: %d", gid, duration, pulls);
      console.log("side: %d, tokenId %d, marker %d", gotSide, tokenId, marker);
      */
    }

    function _run() public {

      bytes memory accountCall = abi.encodeWithSignature("joinSide(uint256)", side);
      ERC6551Account account = ERC6551Account(payable(boundAddr));
      account.execute(payable(tugawarAddr), 0, accountCall, 0);
    }

    function env() public {
      _env(true);
      _envSecret(true);
    }

    function _env(bool show) public {

      // !NOTE: That env file parsing in foundry is super senstive to syntax errors
      // - miss a 0x prefix and the key wont be available to envUint
      // - make a // comment instead of a # bash style and the whole env will
      //   be missing
      // run env
      keyName = vm.envOr("KEYNAME", string(""));
      tugawarAddr = vm.envOr("TUGAWAR_ADDR", LAST_KNOWN_TUGAWAR_ADDR);
      boundAddr = vm.envOr("BOUND", vm.envOr("POLYZONE_BOUND", address(0)));
      side = vm.envOr("SIDE", uint256(0)); // zero choses open side or creates new game

      // test env
      holderPub = vm.envOr("HOLDER_PUB", vm.envOr("POLYZONE_PUB", address(0)));
      boundAddr = vm.envOr("BOUND", vm.envOr("POLYZONE_BOUND", address(0)));
      if (!show)
        return;

      console.log("KEYNAME: %s", keyName);
      console.log("TUGAWAR_ADDR: %x", tugawarAddr);
      console.log("HOLDER_PUB: %x", holderPub);
      console.log("BOUND: %x", boundAddr);
      console.log("SIDE: %d", side);

      console.log("POLYZONE_PUB: %x", vm.envOr("POLYZONE_PUB", address(0)));
    }
    function _envSecret(bool show) public view {
      if (!show)
        return;
      console.log("KEY: %x", vm.envOr(keyName, uint256(0)));
    }
}
