// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Event.sol";
import "./interface/IEventFactory.sol";

contract EventFactory is IEventFactory {
    IWeb3BetsFO immutable private app;
    address[] private events;
    mapping(address => string) private names;
    mapping(address => string) private categories;
    mapping(address => string) private subCategories;

    event EventCreated(address eventAddress, address eventOwner);

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

    function getString(address _event) external view override returns(EventString memory)
    {
        EventString memory details = EventString(
            names[_event],
            categories[_event],
            subCategories[_event]
        );
        return details;
    }

    function createEvent(
        string calldata _name,
        string calldata _cat,
        string calldata _sub
    ) external override returns(address)
    {
        require(app.isEventAdmin(msg.sender) && app.isBlack(msg.sender), "F2");
        Event e = new Event(msg.sender, address(app));
        events.push(address(e));
        names[address(e)] = _name;
        categories[address(e)] = _cat;
        subCategories[address(e)] = _sub;

        emit EventCreated(address(e), msg.sender);
        return address(e);
    }

    function setName(address _event, string calldata _name) external override onlyEventOwner(_event)
    {
        names[_event] = _name;
    }

    function setCategory(address _event, string calldata _cat) external override onlyEventOwner(_event)
    {
        categories[_event] = _cat;
    }

    function setSubcategory(address _event, string calldata _sub) external override onlyEventOwner(_event)
    {
        subCategories[_event] = _sub;
    }
}