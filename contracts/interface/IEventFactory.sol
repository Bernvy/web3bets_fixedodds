// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IEventFactory {
    struct EventString {
        string eventName;
        string eventCat;
        string eventSub;
    }

    function getFactory() external view returns(address);

    function getEvents() external view returns(address[] memory);

    function getString(address _event) external view returns(EventString memory);

    function createEvent(string calldata _name, string calldata _cat, string calldata _sub) external returns(address);

    function setName(address _event, string calldata _name) external;

    function setCategory(address _event, string calldata _cat) external;

    function setSubcategory(address _event, string calldata _sub) external;

}