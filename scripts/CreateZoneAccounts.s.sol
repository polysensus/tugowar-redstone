// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/Script.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC6551LastExecutor} from "src/IERC6551LastExecutor.sol";
import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";
import {ERC6551Account} from "src/ERC6551Account.sol";

import {DeployScriptBase} from "./DeployScriptBase.sol";
import {TugAWar} from "src/TugAWar.sol";

// The token bound accounts for the zone tokens need to be created
// They are counterfactual and so can be created *before* the zone tokens are
// minted. This script creates an arbitrary number of them
//
// recipies
//  create first 10 in anvil, automatically deploy the account implementation.
//   source .env.local
//   forge script scripts/CreateZoneTBAs.s.sol
//
contract CreateZoneAccountsScript is DeployScriptBase {

  function run() public {
    startBroadcast();
    _run();
    vm.stopBroadcast();
  }

  function _run() public {


    bytes32 deploymentSalt = vm.envOr("SALT", bytes32("ds.polysensus.com"));
    // Assumes the token alocates id's as simple consecutive numbers. This is
    // by no means guaranteed to be the case, but it is true for downstream
    uint256 firstTokenId = vm.envOr("START", uint256(1));
    uint256 accountCount = vm.envOr("COUNT", uint256(5));

    address EIP6551_REGISTRY = vm.envAddress("ERC6551_REGISTRY");
    address payable EIP6551_ACCOUNT_IMLEMENTATION_ADDRESS = payable(vm.envAddress("ERC6551_ACCOUNT_IMLEMENTATION_ADDRESS"));
    address DS_ZONE_ADDR = vm.envAddress("DS_ZONE_ADDR");

    // todo: we could check the accounts exist rather than expecting the caller
    // to know
    ERC6551Account accountImplementation = ERC6551Account(EIP6551_ACCOUNT_IMLEMENTATION_ADDRESS);


    IERC6551Registry registry = IERC6551Registry(EIP6551_REGISTRY);

    console.log("registry:", address(registry));
    console.log("accountImplementation:", address(accountImplementation));
    console.log("zoneAddress:", DS_ZONE_ADDR);


    for (uint256 id=firstTokenId; id < firstTokenId + accountCount; id++) {

      address zoneAccountAddress = registry.createAccount(
        address(accountImplementation), deploymentSalt, block.chainid,
        DS_ZONE_ADDR, id);
      bool ok = IERC165(zoneAccountAddress).supportsInterface(type(IERC6551LastExecutor).interfaceId);
      if (!ok) revert('wtf');

      console.log("zoneAccount:", id, zoneAccountAddress);
    }
  }
}

