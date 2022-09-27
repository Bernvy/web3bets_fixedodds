// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IEventFactory {

    event EventCreated(address eventOwner, string name, address eventAddress);

    function getEventsByOwner(address _account) external view returns(address[] memory);

    function getEvents() external view returns(address[] memory);

    function createEvent(string memory _name, uint _startTime, uint _minimumStake) external returns(address);

    function updateEventName(address _event, string memory _eventTitle) external returns(bool);

    function cancelThisEvent(address _event) external returns(bool);

    function postponeThisEvent(address _event, uint _startTime) external returns(bool);

    function endThisEvent(address _event) external returns(bool);

    function startThisEvent(address _event) external returns(bool);
}