// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2 as console} from "forge-std/Script.sol";
import {DeployScriptBase} from "./DeployScriptBase.sol";

import "./constants.sol";
import {EIP6551_REGISTRY} from "src/constant.sol";
import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {TugAWar} from "src/TugAWar.sol";

contract DeployTugAWarScript is DeployScriptBase {

    address dsZoneAddr;
    address dsTokenAddr;
    address tugawarAddr;
    TugAWar taw; // saved by _run() for the benefit of test() methods

    // state for test*() methods
    address holderPub;
    address boundAddr;
    address implAddr;

    // state for account deployment
    IERC6551Account accImpl;
    bytes32 accSalt;
    uint256 firstTokenId;
    uint256 accountCount;

    function help() public pure {
      console.log("-s run() | -s createzoneacc() -s test() | -s env() | -s testenv()");
    }

  function run() public {
    startBroadcast();
    _env(false);
    _run();
    vm.stopBroadcast();
  }

  function runf() public {
    startFork();
    _env(false);
    _run();
    vm.stopPrank();
  }

  function _run() public {

    address [] memory allowedTokens = new address[](2);
    allowedTokens[0] = dsZoneAddr; // vm.envAddress("DS_ZONE_ADDR");
    allowedTokens[1] = dsTokenAddr; // vm.envAddress("DS_TOKEN_ADDR");
    taw = new TugAWar(allowedTokens, implAddr);
    console.log("_run: implAddr: %x", address(implAddr));
    console.log("_run: tugawar: %x", address(taw));
  }

  function createzac() public {
    startBroadcast();
    _env(false);
    _createzac();
    vm.stopBroadcast();
  }

  function createzacf() public {
    startFork();
    _env(false);
    _createzac();
    vm.stopPrank();
  }

  function _createzac() public {

    IERC6551Registry registry = IERC6551Registry(EIP6551_REGISTRY);
    accImpl = IERC6551Account(payable(implAddr));

    console.log("registry:", address(registry));
    console.log("accImpl:", address(accImpl));
    console.log("zoneAddress:", dsZoneAddr);


    for (uint256 id=firstTokenId; id < firstTokenId + accountCount; id++) {

      address zoneAccountAddress = registry.createAccount(
        address(accImpl), accSalt, block.chainid, dsZoneAddr, id);
      console.log("zoneAccount:", id, zoneAccountAddress);
    }
  }

  function test() public {
    runf();
    // taw = TugAWar(tugawarAddr);
    console.log("tugawarAddr: %x", tugawarAddr);

    vm.startPrank(holderPub);
    console.log("calling as: %x, boundAddr: %x", holderPub, boundAddr);

    ERC6551Account account = ERC6551Account(payable(boundAddr));
    bytes memory accountCall;
    bytes memory result;

    accountCall = abi.encodeWithSignature("joinSide(uint256)", 0);
    result = account.execute(payable(address(taw)), 0, accountCall, 0);
    abi.decode(result, ());
    uint256 gid; uint256 duration; uint256 pulls; uint256 side; uint256 tokenId; uint256 marker;
    (
      gid, duration, pulls, side, tokenId, marker
    ) = taw.getGameByAccount(boundAddr);
    console.log("gid: %d, duration: %d, pulls: %d", gid, duration, pulls);
    console.log("side: %d, tokenId %d, marker %d", side, tokenId, marker);
  }

  // --- environments

  function env() public {_env(true);}

  function _env(bool show) public {
      // !NOTE: That env file parsing in foundry is super senstive to syntax errors
      // - miss a 0x prefix and the key wont be available to envUint
      // - make a // comment instead of a # bash style and the whole env will
      //   be missing

      // run env
      tugawarAddr = vm.envOr("TUGAWAR_ADDR", LAST_KNOWN_TUGAWAR_ADDR);
      dsZoneAddr = vm.envAddress("DS_ZONE_ADDR");
      dsTokenAddr = vm.envAddress("DS_TOKEN_ADDR");

      // test env
      holderPub = vm.envOr("HOLDER_PUB", vm.envOr("POLYZONE_PUB", address(0)));
      boundAddr = vm.envOr("BOUND", vm.envOr("POLYZONE_BOUND", address(0)));
      implAddr = vm.envOr("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS", vm.envOr("IMPL_ADDR", LAST_KNOWN_IMPLEMENTATION_ADDR));

      // account deployment env
    
      // EIP6551_REGISTRY = vm.envAddress("ERC6551_REGISTRY");
      accSalt = vm.envOr("SALT", bytes32("ds.polysensus.com"));
      firstTokenId = vm.envOr("START", vm.envOr("POLYZONE_TOKENID", uint256(1)));
      accountCount = vm.envOr("COUNT", uint256(1));

      if (!show)
        return;

      console.log("--- chain:");
      console.log("FORK_BLOCK: %d", FORK_BLOCK);
      console.log("RPC", vm.rpcUrl("rpc"));

      console.log("--- erc 6551:");
      console.log("ERC6551_REGISTRY: %x", EIP6551_REGISTRY);
      console.log("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS", vm.envOr("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS", address(0)));
      console.log("IMPL_ADDR: %x", implAddr);
      console.log("SALT: %x", uint256(accSalt));

      console.log("--- game:");
      console.log("TUGAWAR_ADDR: %x", tugawarAddr);
      console.log("DS_ZONE_ADDR: %x", dsZoneAddr);
      console.log("DS_TOKEN_ADDR: %x", dsTokenAddr);
      console.log("--- player:");
      console.log("BOUND: %x", boundAddr);
      console.log("HOLDER_PUB: %x", holderPub);
      console.log("POLYZONE_TOKENID", vm.envOr("POLYZONE_TOKENID", uint256(1)));
      console.log("START", firstTokenId);
      console.log("COUNT", accountCount);
    }
}

