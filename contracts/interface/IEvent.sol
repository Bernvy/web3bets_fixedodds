// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IEvent {
    struct Winner {
        address market;
        uint winningSide;
    }

    event MarketCreated(address eventAddress, address marketAddress);

    function status() external view returns(uint256);

    function owner() external view returns(address);

    function getMarkets() external view returns(address[] memory);

    function start() external;

    function end() external;

    function cancel() external;

    function createMarket() external returns(address);

    function setMarketsWinners(Winner[] calldata _winners) external;

    function settleMarkets(Winner[] calldata _winners) external;

}