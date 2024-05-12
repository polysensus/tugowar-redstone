// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

// --- test framework imports
import {Test} from "forge-std/Test.sol";
import {console2 as console } from "forge-std/console2.sol";

import  {ForkTestBase} from "./ForkTestBase.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";

import  {ForkTestBase} from "./ForkTestBase.sol";

import {CreateZoneAccountsScript} from "scripts/CreateZoneAccounts.s.sol";


contract CreateZoneAccountsScriptTest is ForkTestBase {

  function setUp() public override {
    super.setUp();
  }

  function test_CreateZoneTokenBountAccountsScript() public {
    if (!vm.envOr("ENABLE_FORK_TESTS", false)) return;
    assertEq(vm.activeFork(), fork);
    vm.selectFork(fork);

    CreateZoneAccountsScript s = new CreateZoneAccountsScript();
    vm.setEnv("START",  "1");
    vm.setEnv("COUNT", "3");
    startBroadcast("DEPLOY_PUB");
    s._run();
    vm.stopBroadcast();
  }
}
