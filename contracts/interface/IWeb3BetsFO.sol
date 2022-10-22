// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWeb3BetsFO{
    event FactoryCreated(address factoryAddress);

    function holdAddr() external view returns(address);

    function ecoAddr() external view returns(address);

    function scAddr() external view returns(address);

    function hVig() external view returns(uint256);

    function eVig() external view returns(uint256);

    function aVig() external view returns(uint256);

    function vig() external view returns(uint256);

    function minStake() external view returns(uint256);

    function isBlack(address _addr) external view returns(bool);

    function isEventAdmin(address _addr) external view returns(bool);
}