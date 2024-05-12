pragma solidity ^0.8.23;

// --- test framework imports
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import  {ForkTestBase} from "./ForkTestBase.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";

import {TugAWar, SideInit, SideJoined, GameStarted, Victory} from "src/TugAWar.sol";


contract GetWinnerTest is ForkTestBase {

  function setUp() public override {
    super.setUp();

    createTAW();
    readAccountEnvAll();
  }

  function test_getLightWin() public {
    joinBoth();
    // pull 5 times
    polyPullLight();
    polyPullLight();
    polyPullLight();
    polyPullLight();
    polyPullLight();

    vm.startPrank(polyPub);
    bytes memory result = boundCall(polyBound, address(taw), abi.encodeWithSignature("getWin(uint256)", uint256(0)));


    (uint256 gid, /*uint256 duration*/, uint256 pulls, uint256 side, uint256 tokenId, address winner) = abi.decode(result, (uint256, uint256, uint256, uint256, uint256, address));
    vm.assertEq(gid, 1);
    vm.assertEq(pulls, 5);
    vm.assertEq(side, 1);
    vm.assertEq(tokenId, polyTokenId);
    vm.assertEq(winner, polyPub);
    // duration is tricker to test deterministically, its the block range of
    // the game
  }

  function test_getDarkWin() public {
    joinBoth();
    // pull 5 times
    knightPullDark();
    knightPullDark();
    knightPullDark();
    knightPullDark();
    knightPullDark();

    vm.startPrank(darkPub);
    bytes memory result = boundCall(darkBound, address(taw), abi.encodeWithSignature("getWin(uint256)", uint256(0)));


    (uint256 gid, /*uint256 duration*/, uint256 pulls, uint256 side, uint256 tokenId, address winner) = abi.decode(result, (uint256, uint256, uint256, uint256, uint256, address));
    vm.assertEq(gid, 1);
    vm.assertEq(pulls, 5);
    vm.assertEq(side, 2);
    vm.assertEq(tokenId, darkTokenId);
    vm.assertEq(winner, darkPub);
    // duration is tricker to test deterministically, its the block range of
    // the game
  }

  function test_getLightWinner() public {
    joinBoth();
    // pull 5 times
    polyPullLight();
    polyPullLight();
    polyPullLight();
    polyPullLight();
    polyPullLight();

    vm.startPrank(polyPub);
    bytes memory result = boundCall(polyBound, address(taw), abi.encodeWithSignature("getWinner(uint256)", uint256(0)));

    (uint256 gid, address winner) = abi.decode(result, (uint256, address));
    vm.assertEq(gid, 1);
    vm.assertEq(winner, polyPub);
  }

  function test_getDarkWinner() public {
    joinBoth();

    knightPullDark();
    knightPullDark();
    knightPullDark();
    knightPullDark();
    knightPullDark();

    vm.startPrank(darkPub);
    bytes memory result = boundCall(darkBound, address(taw), abi.encodeWithSignature("getWinner(uint256)", uint256(0)));

    (uint256 gid, address winner) = abi.decode(result, (uint256, address));
    vm.assertEq(gid, 1);
    vm.assertEq(winner, darkPub);
  }
}
