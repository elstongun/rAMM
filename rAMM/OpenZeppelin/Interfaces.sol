// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface ICallOptionBid {
    function amountWanted() external view returns (uint256);

    function tokenWanted() external view returns (address);
}

interface IRetainerBidBid {
    function amountWanted() external view returns (uint256);

    function tokenWanted() external view returns (address);
}

interface IOwnable {
    function owner() external view returns (address);
}