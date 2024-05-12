// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {console} from "forge-std/Test.sol";

import "./constant.sol";
import "./errors.sol";
import "./events.sol";

import "./LibGameStructs.sol";

library LibGame {

    using LibGame for Game;

    function otherSide(uint256 side) internal pure returns (uint256) {
      if (side == lightSide)
        return darkSide;
      return lightSide;
    }

    function inProgress(Game storage g) internal view returns (bool) {
      // No valid started game ever has marker == 0, and the game completes
      // when it reaches either the hi or lo line
      return (g.marker != 0 && g.marker != hiLine && g.marker != loLine);
    }

    function openSide(Game storage g, uint256 preferred) internal view returns (uint256) {

      if (preferred == lightSide) {
        if (g.light.joinSender == address(0))
          return lightSide;
        return 0;
      }
      if (preferred == darkSide) {
        if (g.dark.joinSender == address(0))
          return darkSide;
        return 0;
      }

      // make dark the default just because batman is cooler
      if (g.dark.joinSender == address(0))
        return darkSide;
      if (g.light.joinSender == address(0))
        return lightSide;
      return 0;
    }

    function canJoin(Game storage g) internal view returns (bool) {
      if (g.light.joinSender == address(0)
          || g.dark.joinSender == address(0))
        return true;
      return false;
    }

    function canJoin(Game storage g, uint256 side) internal view returns (bool) {
      if (side == lightSide && g.light.joinSender == address(0))
        return true;
      if (side == darkSide && g.dark.joinSender == address(0))
        return true;
      return false;
    }

    function getSideInit(Game storage g, uint256 side) internal view returns (SideInit storage) {
      if (side == lightSide) {
        return g.light;
      } else if (side == darkSide) {
        return g.dark;
      } else
        revert InvalidSide(side);
    }

    function getTokenSideInit(Game storage g, uint256 tokenId) internal view returns (SideInit storage) {
      // Note: this assumes token has been checked or is known
      if (g.light.tokenId == tokenId) {
        return g.light;
      } else if (g.dark.tokenId == tokenId) {
        return g.dark;
      } else
        revert ("token does not match either side");
    }

    function join(Game storage g, uint256 side, address accImpl, address token, uint256 tokenId, address holder) internal {
      SideInit storage s = g.getSideInit(side);
      if (s.joinSender != address(0))
        revert ("side is already joined");

      s.side = side;
      g.firstBlock = block.number;
      s.joinSender = msg.sender;
      s.accImpl = accImpl;
      s.token = token;
      s.tokenId = tokenId;
      s.holders.push(holder);

      SideInit storage o = g.getSideInit(otherSide(side));
      if (o.joinSender == address(0))
        return;

      // both sides have joined set the rope to the start position
      g.marker = startLine;
    }

    function add(Game storage g, uint256 gid, uint256 tokenId, address holder) internal returns (bool) {
      if (g.light.tokenId != tokenId)
        revert NotInTheLight(gid, tokenId);

      if (g.dark.joinSender == address(0))
        revert GameNotStarted(gid);

      // avoids weird states, shouldn't happen
      if (g.marker >= hiLine || g.marker <= loLine) revert GameOver(gid);

      g.marker += 1;

      g.light.holders.push(holder);

      emit RopePosition(gid, lightSide, holder, g.marker);

      if (g.marker < hiLine)
        return true; // can add again

      g.declareWinner();

      emit Victory(gid, tokenId, holder, lightSide);

      return false; // game over
    }

    function sub(Game storage g, uint256 gid, uint256 tokenId, address holder) internal returns (bool) {
      if (g.dark.tokenId != tokenId)
        revert NotInTheDark(gid, tokenId);

      if (g.light.joinSender == address(0))
        revert GameNotStarted(gid);

      // avoids weird states, shouldn't happen
      if (g.marker >= hiLine || g.marker <= loLine) revert GameOver(gid);

      g.marker -= 1;

      g.dark.holders.push(holder);
      emit RopePosition(gid, darkSide, holder, g.marker);

      if (g.marker > loLine)
        return true; // can sub again

      g.declareWinner();

      emit Victory(gid, tokenId, holder, darkSide);
      return false; // game over
    }

    function declareWinner(Game storage g) internal {

      // we know msg.sender holds the winning token id
      //
      (, /*address tokenContract*/, uint256 winnerTokenId) = IERC6551Account(payable(msg.sender)).token();

      SideInit storage s = g.getTokenSideInit(winnerTokenId);
      if (s.side == lightSide && g.marker != hiLine)
        revert InvalidVictoryState(s.side, g.marker);
      if (s.side == darkSide && g.marker != loLine)
        revert InvalidVictoryState(s.side, g.marker);

      g.winnerId = s.tokenId;
      g.winningSide = s.side;
      g.victoryBlock = block.number;
    }
}
