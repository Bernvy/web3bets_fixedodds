// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMarket{

    function eventAddress() external view returns (address);

    function hasSetWinningSide() external view returns (bool);

    function winningSide() external view returns (string memory);

    function name() external view returns (string memory);

    function isCanceled() external view returns (bool);

    function sideAName() external view returns (string memory);

    function sideBName() external view returns (string memory);

    function sideATotalStake() external view returns (uint);

    function sideBTotalStake() external view returns (uint);

    function addBet(address _better, address _betAddress, uint256 _stake, uint8 _odds, string memory _side) external returns(bool);

    function settlePair(address _pair) external returns(bool);

    // Setting a winning side marks a market as settled
    function setWinningSide(string memory _winningSide) external returns(bool);

    function withdrawPending(address _betAddr) external returns (bool);

    function cancelMarket() external returns(bool);

    function upadteMarket(string memory name_, string memory sideAName_, string memory sideBName_) external returns(bool);

}