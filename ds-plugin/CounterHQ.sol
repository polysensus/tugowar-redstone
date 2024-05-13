// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Game} from "cog/IGame.sol";
import {State} from "cog/IState.sol";
import {Schema} from "@ds/schema/Schema.sol";
import {Actions} from "@ds/actions/Actions.sol";
import {BuildingKind} from "@ds/ext/BuildingKind.sol";
import {IERC6551Registry} from "./IERC6551Registry.sol";
import {TugAWar, FakeTugAWar} from "./TugAWar.sol";
import {
  TUGAWAR_ADDR, DS_ZONE_ADDR, DS_TOKEN_ADDR,
  ERC6551REGISTRY_ADDR,
  ERC6551ACCOUNT_IMPL_ADDR,
  ERC6551_ACCOUNT_SALT
} from "./config.sol";

using Schema for State;

struct GameState {
  uint256 gid;
  uint256 duration;
  uint256 pulls;
  uint256 side;
  uint256 tokenId;
  uint256 marker;
  address winner;
}

contract CounterHQ is BuildingKind {

    function readScore(uint256 tokenId) external {}
    function getWinner(uint256 gid) external view returns (uint256, address) {}
    function Quit() external {}

    function use(Game ds, bytes24 buildingInstance, bytes24, /*actor*/ bytes calldata payload) public override {

        TugAWar taw = TugAWar(TUGAWAR_ADDR);
        // TugAWar taw = new FakeTugAWar();

        if ((bytes4)(payload) == this.readScore.selector) {
          (uint256 id) = abi.decode(payload[4:], (uint256));
          GameState memory gs = stateForId(taw, id);
          _updateScore(ds, taw, buildingInstance, gs);
        }
        else if ((bytes4)(payload) == this.getWinner.selector) {
          (uint256 gid) = abi.decode(payload[4:], (uint256));
          GameState memory gs = winnerForGID(taw, gid);
          _updateScore(ds, taw, buildingInstance, gs);
        }
    }

    function _updateScore(Game ds, TugAWar taw, bytes24 buildingInstance, GameState memory gs) internal {

        // set score
        ds.getDispatcher().dispatch(
            abi.encodeCall(Actions.SET_DATA_ON_BUILDING, (buildingInstance, "score", bytes32(gs.marker)))
        );
        ds.getDispatcher().dispatch(
            abi.encodeCall(Actions.SET_DATA_ON_BUILDING, (buildingInstance, "duration", bytes32(gs.duration)))
        );
        ds.getDispatcher().dispatch(
            abi.encodeCall(Actions.SET_DATA_ON_BUILDING, (buildingInstance, "gid", bytes32(gs.gid)))
        );
        ds.getDispatcher().dispatch(
            abi.encodeCall(Actions.SET_DATA_ON_BUILDING, (buildingInstance, "tokenid", bytes32(gs.tokenId)))
        );

        bytes32 winner = bytes32(uint256(uint160(gs.winner)));
        ds.getDispatcher().dispatch(
            abi.encodeCall(Actions.SET_DATA_ON_BUILDING, (buildingInstance, "winner", winner))
        );

        uint256 complete;
        if (gs.marker == 5 || gs.marker == 15)
          complete = 1;
        ds.getDispatcher().dispatch(
            abi.encodeCall(Actions.SET_DATA_ON_BUILDING, (buildingInstance, "complete", bytes32(complete)))
        );
    }

    // given a downstream item token or zone id, get the game state for the
    // came currenly in progress for the holder
    function stateForId(TugAWar taw, uint256 id) internal view returns (GameState memory) {
      GameState memory gs;
      address acc = accountWithCode(id);
      if (acc.code.length == 0) return gs; // all zeros

      (gs.gid, gs.duration, gs.pulls, gs.side, gs.tokenId, gs.marker) = taw.getGameByAccount(acc);
      return gs;
    }


    // Given a tugawar game id, get the winning state
    function winnerForGID(TugAWar taw, uint256 gid) internal view returns (GameState memory) {
      GameState memory gs;
      (gs.gid, gs.duration, gs.pulls, gs.side, gs.tokenId, gs.winner) = taw.getWin(gid);
      return gs;
    }

    function accountWithCode(uint256 id) internal view returns (address) {

      address acc;
      acc = account(DS_TOKEN_ADDR, id);
      if (acc.code.length == 0)
          return acc;
      return account(DS_ZONE_ADDR, id);
    }
    function account(address zoneOrTokenContract, uint256 id) internal view returns (address) {
      IERC6551Registry reg = IERC6551Registry(ERC6551REGISTRY_ADDR);
      return reg.account(
        ERC6551ACCOUNT_IMPL_ADDR, ERC6551_ACCOUNT_SALT, block.chainid, zoneOrTokenContract, id);
    }
}
