// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2 as console} from "forge-std/Script.sol";
import "src/errors.sol";

contract ShowErrScript {

    function run() public {
      console.logBytes4(OtherGameIncomplete.selector);
      console.logBytes4(NotActiveInGame.selector);

      console.logBytes4(AccountNotActiveInGame.selector);
      console.logBytes4(NotInTheLight.selector);
      console.logBytes4(NotInTheDark.selector);
      console.logBytes4(GameNotStarted.selector);
      console.logBytes4(GameOver.selector);
      console.logBytes4(InvalidSide.selector);
      console.logBytes4(InvalidVictoryState.selector);
      
      console.logBytes4(InvalidTBA.selector);
      console.logBytes4(InvalidToken.selector);
    }
}
