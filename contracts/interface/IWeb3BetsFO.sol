// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWeb3BetsFO{
    function contractOwner() external view returns(address);

    function holdAddr() external view returns(address);

    function ecoAddr() external view returns(address);

    function scAddr() external view returns(address);

    function hVig() external view returns(uint256);

    function eVig() external view returns(uint256);

    function aVig() external view returns(uint256);

    function vig() external view returns(uint256);

    function minStake() external view returns(uint256);

    function isBlack(address _addr) external view returns(bool);
    
    function getEvents() external view returns(bytes32[] memory);

    function getMarkets(bytes32 _event) external view returns(address[] memory);
}