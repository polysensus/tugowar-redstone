// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface TugAWar {       
    function getCurrentMarker(uint256 gid) external view returns (uint256);
    function getGameByAccount(address account) external view returns (
      uint256, uint256, uint256, uint256, uint256, uint256);

    function getWinner(uint256 gid) external view returns (uint256, address);
    function getWin(uint256 gid) external view returns (uint256, uint256, uint256, uint256, uint256, address);
}

contract FakeTugAWar is TugAWar {       
    function getCurrentMarker(uint256 gid) public view returns (uint256) {
      return (uint256)(10);
    }
    function getGameByAccount(address account) public view returns (
      uint256, uint256, uint256, uint256, uint256, uint256) {
      return (0, 0, 0, 0, 0, 0);
    }
    function getWinner(uint256 gid) public view returns (uint256, address) {
      return (0, address(0));
    }
    function getWin(uint256 gid) public view returns (uint256, uint256, uint256, uint256, uint256, address) {
      return (0, 0, 0, 0, 0, address(0));
    }
}
