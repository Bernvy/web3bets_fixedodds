// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IMarketFactory {

    event MarketCreated(address marketAddress, address eventAddress, string marketName);

    function createMarket(string memory _name, address _eventAddress, string memory _sideAName,string memory _sideBName) external returns(address);

    function withdraw(address _betAddr) external returns(bool);

    function settle(address _pairAddr) external returns(bool);

    function setWinner(address _marketAddr, string memory _side) external returns(bool);

    function update(address _marketAddr, string memory _name, string memory _sideAName, string memory _sideBName) external returns(bool);

    function cancel(address _marketAddr) external returns(bool);

}