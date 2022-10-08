// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWeb3BetsFO{

    function holdAddr() external view returns(address);

    function ecoAddr() external view returns(address);

    function scAddr() external view returns(address);

    function isBlack(address _addr) external view returns(bool);

    function hVig() external view returns(uint256);

    function eVig() external view returns(uint256);

    function aVig() external view returns(uint256);

    function vig() external view returns(uint256);
}