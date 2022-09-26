// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IBet {

    function stake() external view returns(uint);

    function odds() external view returns(uint8);

    function matched() external view returns(uint);

    function better() external view returns(address);

    function marketSide() external view returns (string memory);

    function marketAddress() external view returns (address);

    function getBetPairs() external  returns (address[] memory);

    function addPair(address pairAddress) external returns(bool);

    function setMatched(uint _amount) external returns(bool);

    function withdrawPending() external;
}