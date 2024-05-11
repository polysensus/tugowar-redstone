// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {console} from "forge-std/Test.sol";

uint256 constant startLine = 10;
uint256 constant hiLine = 15;
uint256 constant loLine = 5;

// if deployed the standard way using nick's method, the regsitry is at the
// same address on all chains (and has no owner). There is no requirement to
// use that registry however. We use foundry fork tests to deal with this
address constant EIP6551_REGISTRY = address(0x000000006551c19487814612e58FE06813775758);

struct GameResult {
  address winner;
  address finalLightPlayer;
  address finalDarkPlayer;

  // TODO: leader board based on blocks to complete the tug 'a war
  // uint256 numBlocks;
}

// TugAWar is a game that can only be played if you are a holder of a
// Downstream Zone 721 token
//
// This game is a bit light daily thompsons decathlon, but instead of smashing
// buttons you issue your transactions as fast as you can. If you can write
// a bot for this game you will win every game.
//
// The aim is to show that without changing the origin game (downstream), we can have
// players in that game interact with another using ERC 6551's Token Bound
// Accounts.
//
// It does require those players to use the command line and issue transactions for now.
//
// We think we can probably do ticket based escrow for Primordia using this but
// probably wont get that done today.
contract TugAWar {
    uint256 public nextGame;

    uint256 lightPlayerTokenId;
    uint256 darkPlayerTokenId;

    // TODO: leader board based on blocks to complete
    // uint256 firstBlock;
    // uint256 lastBlock;
    uint256 marker;

    // From the PoV of Tug 'A War, the Downstream zone contract is just an ERC
    // 721 token, used to gate access.
    address allowedToken;

    // Could have many allowed implementations. the demo one is tweaked from
    // the reference to support ERC1155, but this could be a well-known deploy
    // of the reference account implementation
    address allowedAccountImplementation;
    
    // maps winner address to the result
    GameResult []results;
    mapping(address => uint256) winners;

    uint256 aatest;

    constructor(address allowedToken_, address allowedAccountImplementation_) {

      allowedToken = allowedToken_;
      allowedAccountImplementation = allowedAccountImplementation_;

      nextGame = 1;
      results.push();

      // alow games to start
      marker = startLine;
    }

    // open access method to test aa sponsored gas transactions
    function aaTestAdd() public returns (uint256) {
      aatest += 1;
      return aatest;
    }

    function getResult(uint256 i) public view returns (GameResult memory) {
      return results[i];
    }

    /**
     *
     */
    function getCurrentRopePosition() public view returns (uint256) {
      return marker;
    }

    function isGameRunning() public view returns (bool) {
      if (lightPlayerTokenId == 0 || darkPlayerTokenId == 0)
          return false;
      return true;
    }

    function joinTheLight() public {

      if (lightPlayerTokenId != 0) revert("there can be only one");

      // check that msg.sender *is* and ERC6551 account bound to the expected
      // account contract. 'allowedAccountImplementation' could just as well be a list or a
      // map.
      if (!ERC6551AccountLib.isERC6551Account(msg.sender, allowedAccountImplementation, EIP6551_REGISTRY))
          revert("must be a token bound account from the expected token contract");

      // Now that we know it is definitely an account tba, we can safely get
      // the token Id and check the token implementation.  Note that we don't
      // care *here* that it is *particularly* the downstream Zone implementation.
      address tokenContract;
      (, tokenContract, lightPlayerTokenId) = IERC6551Account(payable(msg.sender)).token();

      if (tokenContract != allowedToken) revert("account asset class is not allowed");

      if (lightPlayerTokenId == darkPlayerTokenId && darkPlayerTokenId != 0) revert("player accounts must be bound to different tokens");
    }

    function joinTheDark() public {

      if (darkPlayerTokenId != 0) revert("there can be only one");

      // just as for joinTheLight
      if (!ERC6551AccountLib.isERC6551Account(msg.sender, allowedAccountImplementation, EIP6551_REGISTRY)) revert("must be a token bound account from the expected token contract");

      // Check the account implementation is the one we expect and allow
      address tokenContract;
      (, tokenContract, darkPlayerTokenId) = IERC6551Account(payable(msg.sender)).token();
      if (tokenContract != allowedToken) revert("account asset class is not allowed");

      if (darkPlayerTokenId == lightPlayerTokenId && lightPlayerTokenId != 0) revert("player accounts must be bound to different tokens");
    }

    function _senderHoldsRequiredToken(uint256 requiredTokenId) internal view returns (bool) {

      if (!ERC6551AccountLib.isERC6551Account(msg.sender, allowedAccountImplementation, EIP6551_REGISTRY)) return false;
      (, address tokenContract, uint256 tokenId) = IERC6551Account(payable(msg.sender)).token();
      if (tokenContract != allowedToken) revert("account asset class is not allowed");

      if (tokenId != requiredTokenId) return false;
      return true;
    }

    // First one to the line wins, the light player heads to the light (up)
    function Add() public {

      if (lightPlayerTokenId == 0) revert("join the game fist");
      if (darkPlayerTokenId == 0) revert("match not ready");

      if (!_senderHoldsRequiredToken(lightPlayerTokenId)) revert("you must be the light player");

      // avoids weird states, shouldn't happen
      if (marker >= hiLine || marker <= loLine) revert("game over");

      marker += 1;
      if (marker < hiLine)
        return;

      _declareWinner();
    }

    // First one to the line wins, the dark player heads to the depths of hades (down)
    function Sub() public {

      if (darkPlayerTokenId == 0) revert("join the game fist");
      if (lightPlayerTokenId == 0) revert("match not ready");

      if (!_senderHoldsRequiredToken(darkPlayerTokenId)) revert("you must be the dark player");

      // avoids weird states, shouldn't happen
      if (marker >= hiLine || marker <= loLine) revert("game over");

      marker -= 1;
      if (marker != loLine) 
        return;

      _declareWinner();
    }

    function _declareWinner() internal {

      // we know msg.sender holds the winning token id
      //
      (, address tokenContract, uint256 winnerTokenId) = IERC6551Account(payable(msg.sender)).token();
      if (tokenContract != allowedToken) revert("account asset class is not allowed");

      // considering checks callers make this is redundant, but it makes
      // reasoning about test fails easier
      if (winnerTokenId != lightPlayerTokenId && winnerTokenId != darkPlayerTokenId) revert("invalid winner");

      uint256 i = results.length;
      results.push();

      results[i].winner = IERC721(tokenContract).ownerOf(winnerTokenId);

      results[i].finalLightPlayer = IERC721(tokenContract).ownerOf(lightPlayerTokenId);
      results[i].finalDarkPlayer = IERC721(tokenContract).ownerOf(darkPlayerTokenId);

      // Let a new game start
      lightPlayerTokenId = 0;
      darkPlayerTokenId = 0;

      marker = startLine;
      nextGame += 1;
    }
}
