// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWeb3BetsFO{

    function holdAddr() external view returns(address);

    function ecoAddr() external view returns(address);

    function scAddr() external view returns(address);

    // function eventFactory() external view returns(address);

    // function marketFactory() external view returns(address);

    // function betFactory() external view returns(address);

    function hVig() external view returns(uint256);

    function eVig() external view returns(uint256);

    function aVig() external view returns(uint256);

    function vig() external view returns(uint256);

    // function shareBetEarnings() external;

    // function isSystemAdmin(address _account) external returns (uint256);

    // function isEventAdmin(address _account) external returns (uint256);

    // function isBlack(address _account) external returns (uint256);
}