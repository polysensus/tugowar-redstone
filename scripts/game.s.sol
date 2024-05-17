// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Script.sol";
import {ActionScriptBase} from "./ActionScriptBase.sol";
import {TugAWar} from "src/TugAWar.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";
import "./constants.sol";

contract GameScript is ActionScriptBase {

    uint256 FORK_BLOCK;

    function help() public view {
      console.log("-s run() | -s runforked() | -s test() | -s env() | -s testenv()");
    }

    TugAWar taw;

    address implAddr;
    address dsZoneAddr;
    address dsTokenAddr;
    string keyName;
    address tugawarAddr;
    address holderPub;
    address boundAddr;
    uint256 sideToJoin;

    uint256 key;

    function startLive() public {
      _env(false);
      _envSecret(false);
      startBroadcast(keyName);
    }

    function startForked() public {
      console.log("rpc: %s", vm.rpcUrl("rpc"));
      _env(false);
      _envSecret(false);
      createFork(FORK_BLOCK);
      vm.deal(holderPub, 1 << 128);
      vm.startPrank(holderPub);
      console.log("sender: %x", holderPub);
    }

    function gamebyacc() public {
      startLive();
      _gamebyacc();
      vm.stopBroadcast();
    }

    function gamebyaccf() public {
      startForked();
      _gamebyacc();
      vm.stopPrank();
    }

    function _gamebyacc() public {

      uint256 gid; uint256 duration; uint256 pulls; uint256 side; uint256 tokenId; uint256 marker;

      // accountCall = abi.encodeWithSignature("getGameByAccount(address)", boundAddr);
      // result = account.execute(payable(tugawarAddr), 0, accountCall, 0);
      // (
      //   gid, duration, pulls, gotSide, tokenId, marker
      // ) = abi.decode(result, (uint256, uint256, uint256, uint256, uint256, uint256));

      (
        gid, duration, pulls, side, tokenId, marker
      ) = taw.getGameByAccount(boundAddr);
      console.log("gid: %d, duration: %d, pulls: %d", gid, duration, pulls);
      console.log("side: %d, tokenId %d, marker %d", side, tokenId, marker);
    }

    function joinside() public {
      startLive();
      _joinSide();
      _gamebyacc();
      vm.stopBroadcast();
    }

    function joinsidef() public {
      startForked();
      _joinSide();
      _gamebyacc();
      vm.stopPrank();
    }

    function _joinSide() public {

      bytes memory accountCall = abi.encodeWithSignature("joinSide(uint256)", sideToJoin);
      ERC6551Account account = ERC6551Account(payable(boundAddr));
      bytes memory result = account.execute(payable(tugawarAddr), 0, accountCall, 0);
      console.log("result.length: %d", result.length);
      abi.decode(result, ());
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
      //
      FORK_BLOCK = vm.envOr("FORK_BLOCK", uint256(0));

      keyName = vm.envOr("KEYNAME", string(""));
      tugawarAddr = vm.envOr("TUGAWAR_ADDR", LAST_KNOWN_TUGAWAR_ADDR);
      boundAddr = vm.envOr("BOUND", vm.envOr("POLYZONE_BOUND", address(0)));
      sideToJoin = vm.envOr("SIDE", uint256(0)); // zero choses open side or creates new game

      dsZoneAddr = vm.envAddress("DS_ZONE_ADDR");
      dsTokenAddr = vm.envAddress("DS_TOKEN_ADDR");
      implAddr = vm.envOr("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS", vm.envOr("IMPL_ADDR", LAST_KNOWN_IMPLEMENTATION_ADDR));

      // test env
      holderPub = vm.envOr("HOLDER_PUB", vm.envOr("POLYZONE_PUB", address(0)));
      boundAddr = vm.envOr("BOUND", vm.envOr("POLYZONE_BOUND", address(0)));

      taw = TugAWar(tugawarAddr);
      if (!show)
        return;

      console.log("FORK_BLOCK: %d", FORK_BLOCK);
      console.log("RPC", vm.rpcUrl("rpc"));

      console.log("--- erc6551 details");
      console.log("DS_ZONE_ADDR: %x", dsZoneAddr);
      console.log("DS_TOKEN_ADDR: %x", dsTokenAddr);

      console.log("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS", vm.envOr("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS", address(0)));
      console.log("IMPL_ADDR: %x", implAddr);

      console.log("--- player & game details");
      console.log("KEYNAME: %s", keyName);
      console.log("POLYZONE_PUB: %x", vm.envOr("POLYZONE_PUB", address(0)));
      console.log("TUGAWAR_ADDR: %x", tugawarAddr);
      console.log("HOLDER_PUB: %x", holderPub);
      console.log("BOUND: %x", boundAddr);
      console.log("SIDE: %d", sideToJoin);
      console.log("FORK_BLOCK: %s", FORK_BLOCK);

    }
    function _envSecret(bool show) public view {
      if (!show)
        return;
      console.log("KEY: %x", vm.envOr(keyName, uint256(0)));
    }
}
