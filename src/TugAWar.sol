// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IERC6551LastExecutor} from "./IERC6551LastExecutor.sol";

import "forge-std/console.sol";
import "./constant.sol";
import "./errors.sol";

import "./events.sol";

import {SideInit, Game} from "./LibGameStructs.sol";
import {LibGame} from "./LibGame.sol";

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

    using LibGame for Game;

    // From the PoV of Tug 'A War, the Downstream zone contract is just an ERC
    // 721 token, used to gate access.
    address allowedToken;

    // Could have many allowed implementations. the demo one is tweaked from
    // the reference to support ERC1155, but this could be a well-known deploy
    // of the reference account implementation
    address allowedAccountImplementation;
    
    Game []games;
    // maps tokenId's to games, each running game will have an entry in here
    // for each side.
    mapping (uint256 => uint256) tokenGames;

    uint256 aatest;

    constructor(address allowedToken_, address allowedAccountImplementation_) {

      allowedToken = allowedToken_;
      allowedAccountImplementation = allowedAccountImplementation_;

      games.push(); // gids are 1 based, gid 0 is invalid
    }

    // open access method to test aa sponsored gas transactions
    function aaTestAdd() public returns (uint256) {
      aatest += 1;
      return aatest;
    }

    function getGame(uint256 gid) public view returns (Game memory) {
      return games[gid];
    }
    function getGame() public view returns (Game memory) {
      requireSenderAccountImpl(msg.sender);
      (, , uint256 tokenId) = IERC6551Account(payable(msg.sender)).token();
      if (tokenId == 0)
        revert AccountNotActiveInGame(msg.sender);

      uint256 gid = tokenGames[tokenId];
      if (gid == 0)
        revert NotActiveInGame(tokenId);

      return games[gid];
    }


    function getCurrentMarker(uint256 gid) public view returns (uint256) {
      return games[gid].marker;
    }

    function getGameByAccount(address account) public view returns (
      uint256, uint256, uint256, uint256, uint256, uint256) {

      (uint256 gid, uint256 tokenId) = accountGameToken(account);
      if (gid == 0)
        return (0, 0, 0, 0, 0, 0);
      return _getGame(gid, tokenId);
    }

    function _getGame(uint256 gid, uint256 tokenId) internal view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
      if (gid == 0)
        gid = games.length - 1;
      Game storage g = games[gid];

      SideInit storage s;
      if (g.light.tokenId == tokenId) {
        s = g.light;
      } else if (g.dark.tokenId == tokenId) {
        s = g.dark;
      } else
        revert NotActiveInGame(tokenId);

      uint256 duration;
      if (g.victoryBlock != 0)
        duration = g.victoryBlock - g.firstBlock;
      else
        duration = block.number - g.firstBlock;

      // the pulls is length - 1 to account for the join address being the
      // first entry in the holders array
      return (gid, duration, s.holders.length - 1, s.side, s.tokenId, g.marker);
    }

    /**
     * @dev returns the gid, the time (in blocks), the number of pulls to win, the wining side, the wining token and
     * the holder of the token on the winning pull.
     *
     * If the argument gid is zero, the latest game is chosen
     *
     * Reverts if the game doesn't exist
     * Returns all 0's if the game is not complete
     */
    function getWin(uint256 gid) public view returns (uint256, uint256, uint256, uint256, uint256, address) {
      if (gid == 0)
        gid = games.length - 1;
      Game storage g = games[gid];

      if (g.winnerId == 0)
        return (0, 0, 0, 0, 0, address(0));

      SideInit storage s = g.getWinSide();

      uint256 duration = g.victoryBlock - g.firstBlock;
      address winner = s.holders[s.holders.length-1];

      // the pulls is length - 1 to account for the join address being the
      // first entry in the holders array
      return (gid, duration, s.holders.length - 1, s.side, s.tokenId, winner);
    }

    function getWinner(uint256 gid) public view returns (uint256, address) {
      if (gid == 0)
        gid = games.length - 1;
      Game storage g = games[gid];

      if (g.winnerId == 0)
        return (0, address(0));

      SideInit storage s = g.getWinSide();

      return (gid, s.holders[s.holders.length-1]);
    }

    function isGameRunning(uint256 gid) public view returns (bool) {
      return games[gid].inProgress();
    }

    // if the next game is waiting for either or both sides, returns its id
    // otherwise return 0
    function openGameId() public view returns (uint256) {
      if (games[games.length - 1].canJoin())
          return games.length - 1;
      return 0;
    }

    function openGameSide(uint256 preferredOrZero) public view returns (uint256, uint256) {
      uint256 gid = openGameId();
      if (gid == 0)
        return (0, 0);
      return (gid, games[gid].openSide(preferredOrZero));
    }

    function joinSide(uint256 preferredOrZero) public {

      (uint256 gid, uint256 side) = openGameSide(preferredOrZero);
      if (gid == 0)
        side = preferredOrZero;
      // If there are no open games, the default is dark. Otherwise
      // openGameSide will have chosen a default.
      if (gid == 0 && side == 0)
        side = darkSide;

      if (side != lightSide && side != darkSide) revert InvalidSide(side);

      address accImpl = requireSenderAccountImpl(msg.sender);
      (, address tokenContract, uint256 tokenId) = IERC6551Account(payable(msg.sender)).token();
      address holder = IERC6551LastExecutor(msg.sender).lastExecutor(tokenId);

      // Multiple games are supported, but a single tba can only be active in
      // one game at a time.
      if (tokenGames[gid] != 0) revert OtherGameIncomplete();

      if (gid == 0) {
        // the most recently created game has been joined by both the dark and
        // the light
        games.push();
        gid = games.length - 1;
      }
      Game storage g = games[gid];
      g.join(side, accImpl, tokenContract, tokenId, holder); // will revert if side is already joined

      SideInit storage s = g.getSideInit(side);
      tokenGames[s.tokenId] = gid;

      emit SideJoined(gid, msg.sender, tokenId, tokenContract);
      if (g.marker != 0)
        emit GameStarted(gid, g.light, g.dark);
    }

    function accountGameToken(address account) internal view returns (uint256, uint256) {

      uint256 tokenId;
      (bool ok,) = checkSenderAccountImpl(account);
      if (!ok)
        return (0, 0);
      (, /*address tokenContract*/, tokenId) = IERC6551Account(payable(account)).token();
      return (tokenGames[tokenId], tokenId);
    }

    function requireActiveGameToken() internal view returns (uint256, uint256) {
      requireSenderAccountImpl(msg.sender);
      (, /*address tokenContract*/, uint256 tokenId) = IERC6551Account(payable(msg.sender)).token();

      uint256 gid = tokenGames[tokenId];

      if (gid == 0) revert NotActiveInGame(tokenId);

      return (gid, tokenId);
    }

    function requireActiveGameTokenHolder() internal returns (uint256, uint256, address) {

      (uint256 gid, uint256 tokenId) = requireActiveGameToken();

      // TODO: make this view
      address holder = IERC6551LastExecutor(msg.sender).lastExecutor(tokenId);

      return (gid, tokenId, holder);
    }

    function Pull() public returns (bool) {
      (uint256 gid, uint256 tokenId, address holder) = requireActiveGameTokenHolder();

      Game storage g = games[gid];

      if (g.light.tokenId == tokenId) {
        if (g.add(gid, tokenId, holder))
          return true;
        tokenGames[g.dark.tokenId] = 0;
      } else if (g.dark.tokenId == tokenId) {
        if (g.sub(gid, tokenId, holder))
          return true;
        tokenGames[g.light.tokenId] = 0;
      } else
        revert NotActiveInGame(tokenId);
      tokenGames[tokenId] = 0;
      return false; 
    }

    function checkSenderAccountImpl(address sender) internal view returns (bool, address) {
      if (!ERC6551AccountLib.isERC6551Account(
        sender, allowedAccountImplementation, EIP6551_REGISTRY))
          return (false, address(0));
      
      return (true, allowedAccountImplementation);
    }

    function requireSenderAccountImpl(address sender) internal view returns (address) {
      // check that msg.sender *is* and ERC6551 account bound to the expected
      // account contract. 'allowedAccountImplementation' could just as well be a list or a
      // map.
      (bool ok, address accImpl) = checkSenderAccountImpl(sender);
      if (!ok)
          revert InvalidTBA(sender);
      return accImpl;
    }

    function requireAllowedToken(address tokenContract) internal view {
      if (tokenContract != allowedToken) revert InvalidToken(tokenContract);
    }
}
