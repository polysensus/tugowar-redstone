// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// if deployed the standard way using nick's method, the regsitry is at the
// same address on all chains (and has no owner). There is no requirement to
// use that registry however. We use foundry fork tests to deal with this
address constant EIP6551_REGISTRY = address(0x000000006551c19487814612e58FE06813775758);

uint256 constant lightSide = 1;
uint256 constant darkSide = 2;

uint256 constant startLine = 10;
uint256 constant hiLine = 15;
uint256 constant loLine = 5;

