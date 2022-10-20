// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IEvent {
    struct MarketString {
        string marketName;
        string side1;
        string side2;
        string desc;
    }

    function status() external view returns(uint256);

    function startTime() external view returns(uint256);

    function owner() external view returns(address);

    function getMarkets() external view returns(address[] memory);

    function getMarketString(address _market) external view returns(MarketString memory);
    
}