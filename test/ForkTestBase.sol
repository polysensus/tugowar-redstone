// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {ERC6551Account} from "src/ERC6551Account.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";


contract ForkTestBase is Test {

  string RPC = vm.rpcUrl("rpc");
  uint256 FORK_BLOCK = vm.envOr("FORK_BLOCK", uint256(0));
  uint256 fork;

  function forkEnabled() internal view returns (bool) {
      return vm.envOr("ENABLE_FORK_TESTS", false);
  }

  function setUp() public virtual {
      if (!forkEnabled()) return;

      fork = vm.createFork(RPC, FORK_BLOCK);
      vm.selectFork(fork);
  }

  function boundCall(address bound, address tugawar, bytes memory encodedCall) internal {
      ERC6551Account(payable(bound)).execute(payable(tugawar), 0, encodedCall, 0);
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
