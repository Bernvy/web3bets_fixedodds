// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBase.sol";

interface IEvent is IBase{

    enum EventStatus {
        UPCOMING,
        STARTED,
        ENDED,
        CANCELED
    }

    function addMarket(address marketAddress) external returns(bool);

    function updateName(string memory _eventTitle) external returns(bool);

    function cancelEvent() external returns(bool);

    function postponeEvent(uint256 _startTime) external returns(bool);

    function endEvent() external returns(bool);

    function getMarkets() external returns (address[] memory);

    function getMinimumStake() external returns (uint256);

    function getEventOwner() external returns (address);

    function getEventStatus() external returns (EventStatus);

}