// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

error OtherGameIncomplete();
error NotActiveInGame(uint256 tokenId);
error NotInTheLight(uint256 gid, uint256 tokenId);
error NotInTheDark(uint256 gid, uint256 tokenId);
error GameNotStarted(uint256 gid);
error GameOver(uint256 gid);
error InvalidSide(uint256 side);

error InvalidTBA(address sender);
error InvalidToken(address token);

