// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEvent{

    enum EventStatus {
        UPCOMING,
        STARTED,
        ENDED,
        CANCELED
    }

    function minimumStake() external returns (uint256);

    function eventOwner() external returns (address);

    function startTime() external returns (uint);

    function status() external returns (EventStatus);

    function name() external returns (string memory);

    function getMarkets() external returns (address[] memory);

    function addMarket(address marketAddress) external returns(bool);

    function updateName(string memory _eventTitle) external returns(bool);

    function cancelEvent() external returns(bool);

    function postponeEvent(uint256 _startTime) external returns(bool);

    function endEvent() external returns(bool);

    function startEvent() external returns(bool);

}