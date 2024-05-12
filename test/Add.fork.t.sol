pragma solidity ^0.8.23;

// --- test framework imports
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import  {ForkTestBase} from "./ForkTestBase.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";
import {IERC6551LastExecutor} from "src/IERC6551LastExecutor.sol";

import {TugAWar, Game, SideInit, SideJoined, GameStarted, RopePosition} from "src/TugAWar.sol";


contract AddTest is ForkTestBase {

  function setUp() public override {
    if (!forkEnabled()) return;
    super.setUp();

    createTAW();
    readAccountEnvAll();
  }

  function test_accountsSupportLastExecutor() public view {
    if (!forkEnabled()) return;
    console.log(polyBound);
    bool ok = IERC165(polyBound).supportsInterface(type(IERC6551LastExecutor).interfaceId);
    console.log(ok);
    vm.assertEq(ok, true);


    console.log(darkBound);
    ok = IERC165(darkBound).supportsInterface(type(IERC6551LastExecutor).interfaceId);
    console.log(ok);
    vm.assertEq(ok, true);

    console.log(dailyBound);
    ok = IERC165(dailyBound).supportsInterface(type(IERC6551LastExecutor).interfaceId);
    console.log(ok);
    vm.assertEq(ok, true);
  }

  function test_Add() public {
    if (!forkEnabled()) return;

    joinBoth();
    vm.startPrank(polyPub);

    vm.expectEmit(true, true, true, false);
    emit RopePosition(uint256(1), 1, polyPub, 11);
    boundCall(polyBound, address(taw), abi.encodeWithSignature("Add()"));
    vm.stopPrank();
  }
}
