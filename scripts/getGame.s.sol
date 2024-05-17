pragma solidity ^0.8.13;

import {Script, console2 as console} from "forge-std/Script.sol";
import "src/errors.sol";
import {Game, TugAWar} from "src/TugAWar.sol";
import "./constants.sol";

contract getGameScript is Script {

    function run() public {
      TugAWar taw = TugAWar(vm.envOr("TUGAWAR_ADDR", LAST_KNOWN_TUGAWAR_ADDR));

      uint256 gid = vm.envOr("GID", uint256(0));
      console.log("gid: %d, address: %x", gid, address(taw));
      // console.log(taw.games.length);
      // if (taw.games.length <= gid) {
      //   console.log("no game for gid");
      //   return;
      // }
      Game memory gs = taw.getGame(gid);
      console.log(
        "light: side: %d, joinSender: %x, tokenId: %d",
        gs.light.side,
        gs.light.joinSender,
        gs.light.tokenId
      );
      console.log("light: accImpl: %x, token: %x", gs.light.accImpl, gs.light.token);
      console.log(
        "dark: side: %d, joinSender: %x, tokenId: %d",
        gs.dark.side,
        gs.dark.joinSender,
        gs.dark.tokenId
      );
      console.log("dark: accImpl: %x, token: %x", gs.dark.accImpl, gs.dark.token);

      console.log(
        "marker: %d, firstBlock: %d, victoryBlock: %d",
        gs.firstBlock, gs.marker, gs.winnerId);

      // , winnerId: %d, winningSide: %d
        //, gs.winningSide, gs.victoryBlock
    }
}
