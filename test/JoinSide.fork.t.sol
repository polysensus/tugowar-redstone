pragma solidity ^0.8.23;

// --- test framework imports
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import  {ForkTestBase} from "./ForkTestBase.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";

import {TugAWar, SideInit, SideJoined, GameStarted} from "src/TugAWar.sol";


contract JoinSideTest is ForkTestBase {

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

  function setUp() public override {
    super.setUp();
    taw = new TugAWar(
      vm.envAddress("DS_ZONE_ADDR"),
      vm.envAddress("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS"));
    console.log(address(taw));

    polyTokenId = vm.envUint("POLYZONE_TOKENID");
    polyBound = vm.envAddress("POLYZONE_BOUND");
    polyPub = vm.envAddress("POLYZONE_PUB");

    dailyTokenId = vm.envUint("DAILYZONE_TOKENID");
    dailyBound = vm.envAddress("DAILYZONE_BOUND");
    dailyPub = vm.envAddress("DAILYZONE_PUB");

    darkTokenId = vm.envUint("DARKZONE_TOKENID");
    darkBound = vm.envAddress("DARKZONE_BOUND");
    darkPub = vm.envAddress("DARKZONE_PUB");
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
    emit GameStarted(uint256(1), SideInit(0, address(0), address(0), address(0), 0), SideInit(0, address(0), address(0), address(0), 0));
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
    emit GameStarted(uint256(1), SideInit(0, address(0), address(0), address(0), 0), SideInit(0, address(0), address(0), address(0), 0));
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
    emit GameStarted(uint256(1), SideInit(0, address(0), address(0), address(0), 0), SideInit(0, address(0), address(0), address(0), 0));
    boundCall(darkBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(2)));

    vm.startPrank(darkPub);
    vm.expectRevert();
    boundCall(dailyBound, address(taw), abi.encodeWithSignature("joinSide(uint256)", uint256(2)));
  }
}
