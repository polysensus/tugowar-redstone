// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct SideInit {

  uint256 side;
  // the msg.sender when join was called. Useful as the starting point if
  // tracking ownership changes during or after the session.

  address joinSender;

  // implementation addresse for the sides token bound account.
  address accImpl;

  // implementation adress for the token
  address token;

  uint256 tokenId;
}

struct Game {

  SideInit light;
  SideInit dark;
  uint256 firstBlock;
  uint256 marker;

  uint256 winnerId;
  uint256 winningSide;
  // The owner of the token at this block one the game. It requires off chain
  // processing of eth logs to establish that because we support ERC1155 and
  // ownerOf isn't part of that standard. The transaction index isn't needed
  // (or avaialbe from the EVM),there is only one wining tx per game.
  uint256 victoryBlock;
}
