pragma solidity ^0.8.23;

// --- test framework imports
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import  {ForkTestBase} from "./ForkTestBase.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";

import {TugAWar, Game, SideInit, SideJoined, GameStarted, RopePosition} from "src/TugAWar.sol";


contract SubTest is ForkTestBase {

  function setUp() public override {
    if (!forkEnabled()) return;
    super.setUp();

    createTAW();
    readAccountEnvAll();
  }

  function test_Sub() public {
    if (!forkEnabled()) return;
    joinBoth();
    vm.startPrank(darkPub);
    vm.expectEmit(true, true, true, false);
    emit RopePosition(uint256(1), 2, 9);
    boundCall(darkBound, address(taw), abi.encodeWithSignature("Sub()"));
    vm.stopPrank();
  }
}
