pragma solidity ^0.8.23;

// --- test framework imports
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import  {ForkTestBase} from "./ForkTestBase.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";

import {TugAWar, SideInit, SideJoined, GameStarted, Victory} from "src/TugAWar.sol";


contract JoinSideTest is ForkTestBase {

  function setUp() public override {
    super.setUp();

    createTAW();
    readAccountEnvAll();
  }

  function test_joinDefaultSide() public {
    if (!forkEnabled()) return;

    vm.startPrank(polyPub);

    vm.expectEmit(true, true, true, false);
    emit SideJoined(uint256(1), polyBound, polyTokenId, address(0));
    boundCall(polyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(0)));
  }

  function test_joinLight() public {
    if (!forkEnabled()) return;

    vm.startPrank(polyPub);

    vm.expectEmit(true, true, true, false);
    emit SideJoined(uint256(1), polyBound, polyTokenId, address(0));
    boundCall(polyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(2)));
  }

  function test_joinBoth() public {
    if (!forkEnabled()) return;

    vm.startPrank(polyPub);
    vm.expectEmit(true, true, true, false);
    emit SideJoined(uint256(1), polyBound, polyTokenId, address(0));
    boundCall(polyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(1)));

    vm.startPrank(darkPub);
    vm.expectEmit(true, true, true, false);
    emit SideJoined(uint256(1), darkBound, darkTokenId, address(0));
    vm.expectEmit(true, false, false, false);
    emit GameStarted(uint256(1), emptySideInit(), emptySideInit());
    boundCall(darkBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(2)));
  }

  function test_secondGame() public {
    if (!forkEnabled()) return;

    vm.startPrank(polyPub);
    vm.expectEmit(true, true, true, false);
    emit SideJoined(uint256(1), polyBound, polyTokenId, address(0));
    boundCall(polyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(1)));

    vm.startPrank(darkPub);
    vm.expectEmit(true, true, true, false);
    emit SideJoined(uint256(1), darkBound, darkTokenId, address(0));
    vm.expectEmit(true, false, false, false);
    emit GameStarted(uint256(1), emptySideInit(), emptySideInit());
    boundCall(darkBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(2)));

    vm.startPrank(dailyPub);
    vm.expectEmit(true, true, true, false);
    emit SideJoined(uint256(2), dailyBound, dailyTokenId, address(0));
    boundCall(dailyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(1)));
  }

  function test_joinTwoReverts() public {
    if (!forkEnabled()) return;

    vm.startPrank(polyPub);
    vm.expectEmit(true, true, true, false);
    emit SideJoined(uint256(1), polyBound, polyTokenId, address(0));
    boundCall(polyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(1)));

    vm.startPrank(darkPub);
    vm.expectEmit(true, true, true, false);
    emit SideJoined(uint256(1), darkBound, darkTokenId, address(0));
    vm.expectEmit(true, false, false, false);
    emit GameStarted(uint256(1), emptySideInit(), emptySideInit());
    boundCall(darkBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(2)));

    vm.startPrank(darkPub);
    vm.expectRevert();
    boundCall(dailyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(2)));
  }

  function test_winThenJoinAgain() public {
    joinBoth();
    // pull 4 times
    polyPull();

    polyPull();
    polyPull();
    polyPull();
    vm.expectEmit(true, true, true, false);
    emit Victory(uint256(1), polyTokenId, polyPub, 1);
    polyPull();

    // both should be able to join a new game now
    joinBoth();
  }

  function test_winThenJoinThenWinAgain() public {
    joinBoth();
    // pull 4 times
    polyPull();
    polyPull();
    polyPull();
    polyPull();
    vm.expectEmit(true, true, true, false);
    emit Victory(uint256(1), polyTokenId, polyPub,1);
    polyPull();

    // both should be able to join a new game now
    joinBoth();

    knightPull();
    knightPull();
    knightPull();
    knightPull();
    vm.expectEmit(true, true, true, false);
    emit Victory(uint256(2), darkTokenId, darkPub,2);
    knightPull();
  }
}
