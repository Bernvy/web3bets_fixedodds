// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Event.sol";
import "./interface/IEventFactory.sol";

contract EventFactory is IEventFactory {
    mapping (address => address[]) public userEvents;

    address[] public events;

    address private web3betsAddress;

    IWeb3BetsFO private web3bets = IWeb3BetsFO(web3betsAddress);

    constructor(address _web3bets){
        web3betsAddress = _web3bets;
    }

    function getEventsByOwner(address _account) external view override returns(address[] memory){
        return userEvents[_account];
    }

    function getEvents() external view override returns(address[] memory){
        return events;
    }

    function createEvent(
        string memory _name,
        uint _startTime,
        uint _minimumStake
    ) public override returns(address) {
        bool isEventAdmin = web3bets.isEventAdmin(msg.sender);
        bool isBlack = web3bets.isBlack(msg.sender);
        require(isEventAdmin, "only event admins can create event");
        require(!isBlack, "risk accounts are not allowed");
        Event wEvent = new Event(msg.sender, _name, _startTime, _minimumStake);
        
        userEvents[msg.sender].push(address(wEvent));
        events.push(address(wEvent));
        
        emit EventCreated(msg.sender, _name, address(wEvent));
        return address(wEvent);
    }

    function updateEventName(address _eventAddr, string memory _name) external override returns(bool)
    {
        IEvent _event = IEvent(_eventAddr);
        require(msg.sender == _event.eventOwner(), "only event owner can manage event");
        return _event.updateName(_name);
    }

    function cancelThisEvent(address _eventAddr) external override returns(bool)
    {
        IEvent _event = IEvent(_eventAddr);
        require(msg.sender == _event.eventOwner(), "only event owner can manage event");
        return _event.cancelEvent();
    }

    function postponeThisEvent(address _eventAddr, uint _startTime) external override returns(bool)
    {
        IEvent _event = IEvent(_eventAddr);
        require(msg.sender == _event.eventOwner(), "only event owner can manage event");
        return _event.postponeEvent(_startTime);
    }

    function endThisEvent(address _eventAddr) external override returns(bool)
    {
        IEvent _event = IEvent(_eventAddr);
        require(msg.sender == _event.eventOwner(), "only event owner can manage event");
        return _event.endEvent();
    }

    function startThisEvent(address _eventAddr) external override returns(bool)
    {
        IEvent _event = IEvent(_eventAddr);
        require(msg.sender == _event.eventOwner(), "only event owner can manage event");
        return _event.startEvent();
    }
}