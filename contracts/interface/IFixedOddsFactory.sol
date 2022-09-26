// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IFixedOddsFactory {

    function createEvent(string memory _name, uint _startTime, uint _minimumStake) external returns(address);

    function getEventsByOwner(address _account) external view returns(address[] memory);

    function getEvents() external view returns(address[] memory);

    function createMarket(string memory _name, address _eventAddress, string memory _sideAName,string memory _sideBName) external returns(address);

    function placeBet(address _marketAddress, string memory _marketSide, uint256 _stake, uint8 _odds) external returns(address);

}