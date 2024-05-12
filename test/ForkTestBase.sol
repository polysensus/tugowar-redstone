// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {SideInit, TugAWar} from "src/TugAWar.sol";

contract ForkTestBase is Test {

  string RPC = vm.rpcUrl("rpc");
  uint256 FORK_BLOCK = vm.envOr("FORK_BLOCK", uint256(0));
  uint256 fork;

  TugAWar taw;
  uint256 polyTokenId;
  address polyBound;
  address polyPub;
  uint256 dailyTokenId;
  address dailyBound;
  address dailyPub;

  uint256 darkTokenId;
  address darkBound;
  address darkPub;

  function setUp() public virtual {
      if (!forkEnabled()) return;

      fork = vm.createFork(RPC, FORK_BLOCK);
      vm.selectFork(fork);
  }

  function emptySideInit() internal pure returns (SideInit memory) {
    address[] memory holders;
    return SideInit(0, address(0), address(0), address(0), 0, holders);
  }

  function polyJoinLight() internal {
    vm.startPrank(polyPub);
    boundCall(polyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(1)));
    vm.stopPrank();
  }

  function dailyJoinLight() internal {
    vm.startPrank(dailyPub);
    boundCall(dailyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(1)));
    vm.stopPrank();
  }

  function knightJoinDark() internal {
    vm.startPrank(darkPub);
    boundCall(darkBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(2)));
    vm.stopPrank();
  }

  function polyPull() internal returns (bytes memory){
    vm.startPrank(polyPub);
    bytes memory result = boundCall(polyBound, address(taw), abi.encodeWithSignature("Pull()"));
    vm.stopPrank();
    return result;
  }

  function knightPull() internal returns (bytes memory){
    vm.startPrank(darkPub);
    bytes memory result = boundCall(darkBound, address(taw), abi.encodeWithSignature("Pull()"));
    vm.stopPrank();
    return result;
  }

  function joinBoth() internal {
    polyJoinLight();
    knightJoinDark();
  }

  function joinBothDefault() internal {
    vm.startPrank(polyPub);
    boundCall(polyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(0)));
    vm.stopPrank();
    vm.startPrank(darkPub);
    boundCall(darkBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(0)));
    vm.stopPrank();
  }

  function createTAW() internal {
    taw = new TugAWar(
      vm.envAddress("DS_ZONE_ADDR"),
      vm.envAddress("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS"));
    console.log("accImpl, taw");
    console.log(vm.envAddress("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS"));
    console.log(address(taw));
  }

  function readAccountEnvPoly() internal {
    polyTokenId = vm.envUint("POLYZONE_TOKENID");
    polyBound = vm.envAddress("POLYZONE_BOUND");
    polyPub = vm.envAddress("POLYZONE_PUB");
  }

  function readAccountEnvDaily() internal {
    dailyTokenId = vm.envUint("DAILYZONE_TOKENID");
    dailyBound = vm.envAddress("DAILYZONE_BOUND");
    dailyPub = vm.envAddress("DAILYZONE_PUB");
  }

  function readAccountEnvDark() internal {
    darkTokenId = vm.envUint("DARKZONE_TOKENID");
    darkBound = vm.envAddress("DARKZONE_BOUND");
    darkPub = vm.envAddress("DARKZONE_PUB");
  }

  function readAccountEnvAll () internal {
    readAccountEnvPoly();
    readAccountEnvDaily();
    readAccountEnvDark();
  }

  function forkEnabled() internal view returns (bool) {
      return vm.envOr("ENABLE_FORK_TESTS", false);
  }

  function boundCall(address bound, address tugawar, bytes memory encodedCall) internal returns (bytes memory){
      return ERC6551Account(payable(bound)).execute(payable(tugawar), 0, encodedCall, 0);
  }

  function createBoundAccount(uint256 tokenId) internal returns (address) {

    bytes32 deploymentSalt = vm.envOr("SALT", bytes32("ds.polysensus.com"));

    address EIP6551_REGISTRY = vm.envAddress("ERC6551_REGISTRY");
    address payable EIP6551_ACCOUNT_IMLEMENTATION_ADDRESS = payable(vm.envAddress("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS"));
    address DS_ZONE_ADDR = vm.envAddress("DS_ZONE_ADDR");

    ERC6551Account accountImplementation = ERC6551Account(EIP6551_ACCOUNT_IMLEMENTATION_ADDRESS);

    IERC6551Registry registry = IERC6551Registry(EIP6551_REGISTRY);

    return registry.createAccount(
      address(accountImplementation), deploymentSalt, block.chainid,
      DS_ZONE_ADDR, tokenId);
  }

  function startBroadcast(string memory keyName) internal {
    // If keyName is not set, the script is assumed to be run with --ledger
    address key = vm.envOr(keyName, address(0));
    if (key != address(0))
      vm.startBroadcast(key);
    else
      vm.startBroadcast();
  }
}
