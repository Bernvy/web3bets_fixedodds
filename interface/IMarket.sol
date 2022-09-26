// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./IBase.sol";

interface IMarket is IBase{

    function eventAddress() external view returns (address);

    function hasSetWinningSide() external view returns (bool);

    function winningSide() external view returns (string memory);

    function isCanceled() external view returns (bool);

    function sideAName() external view returns (string memory);

    function sideBName() external view returns (string memory);

    function sideATotalStake() external view returns (uint);

    function sideBTotalStake() external view returns (uint);

    function addBet(address _better, address _betAddress, uint256 _stake, uint8 _odds, string memory _side) external returns(bool);

    // function matchBet() external;

    // Setting a winning side marks a market as settled
    function setWinningSide(string memory _winningSide) external returns(bool);

    function getEventName() external returns (string memory);

    function cancelMarket() external returns(bool);

    function upadteMarket(string memory name_, string memory sideAName_, string memory sideBName_) external returns(bool);

}