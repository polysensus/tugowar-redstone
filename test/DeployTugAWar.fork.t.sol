pragma solidity ^0.8.23;

// --- test framework imports
import {Test} from "forge-std/Test.sol";
import {console2 as console } from "forge-std/console2.sol";

import  {ForkTestBase} from "./ForkTestBase.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";

import {DeployTugAWarScript} from "scripts/DeployTugAWar.s.sol";


contract DeployTugAWarScriptTest is ForkTestBase {

  function setUp() public override {
    super.setUp();
  }
  function test_DeployTugAWarScript() public {
    if (!forkEnabled()) return;
    assertEq(vm.activeFork(), fork);
    DeployTugAWarScript s = new DeployTugAWarScript();
    startBroadcast("DEPLOY_PUB");
    s._run();
    vm.stopBroadcast();
  }
}
