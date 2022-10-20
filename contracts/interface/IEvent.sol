// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IEvent {
    struct MarketString {
        string marketName;
        string side1;
        string side2;
        string desc;
    }

    struct Winner {
        address market;
        uint winningSide;
    }

    function status() external view returns(uint256);

    function startTime() external view returns(uint256);

    function owner() external view returns(address);

    function getMarkets() external view returns(address[] memory);

    function getMarketString(address _market) external view returns(MarketString memory);

    function start() external;

    function end() external;

    function cancel() external;

    function createMarket(
        string memory _name,
        string memory _side1,
        string memory _side2,
        string memory _description
    ) external returns(address);

    function setMarketsWinners(Winner[] calldata _winners) external;

    function settleMarkets(Winner[] calldata _winners) external;

}