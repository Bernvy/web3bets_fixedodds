// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Event.sol";
import "./interface/IEventFactory.sol";

contract EventFactory is IEventFactory {
    IWeb3BetsFO immutable private app;
    address[] private events;

    modifier onlyEventOwner(address _event) {
        require(IEvent(_event).owner() == msg.sender, "F1");
        _;
    }

    constructor(){
        app = IWeb3BetsFO(msg.sender);
    }

    function getFactory() external view override returns(address)
    {
        return address(app);
    }

    function getEvents() external view override returns(address[] memory)
    {
        return events;
    }

    function createEvent() external override returns(address)
    {
        require(app.isEventAdmin(msg.sender) && app.isBlack(msg.sender), "F2");
        Event e = new Event(msg.sender, address(app));
        address eventAddress = address(e);
        events.push(eventAddress);

        emit EventCreated(eventAddress, msg.sender);
        return eventAddress;
    }
}