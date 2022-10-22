// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IEventFactory {
    event EventCreated(address eventAddress, address eventOwner);

    function getFactory() external view returns(address);

    function getEvents() external view returns(address[] memory);

    function getUserEvents(address _user) external view returns(address[] memory);

    function createEvent() external returns(address);

}