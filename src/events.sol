// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SideInit} from "./LibGameStructs.sol";

event SideJoined(uint256 indexed gid, address indexed bound, uint256 indexed tokenId, address token);
event GameStarted(
  uint256 indexed gid, SideInit lightInit, SideInit darkInit);
event RopePosition(uint256 indexed gid, uint256 indexed side, uint256 position); 

event Victory(uint256 indexed gid, uint256 indexed tokenId, uint256 indexed side);

