// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../library/Struct.sol";

interface IMarket{
    function status() external view returns (uint256);

    function getBalance(address _user) external view returns(uint256);

    function getUserBets(address _user) external view returns(bytes32[] memory);

    function getBets() external view returns(bytes32[] memory);

    function getBet(bytes32 _bet) external view returns(Struct.MarketBet memory);

    function getBetPairs(bytes32 _bet) external view returns(bytes32[] memory);

    function getPairs() external view returns(bytes32[] memory);

    function getPair(bytes32 _pair) external view returns(Struct.MarketPair memory);

    function withdraw(address _address) external returns(bool);

    function withdrawPending(bytes32 _bet) external;

    function cancelBet(bytes32 _bet) external;

    function settleBet(bytes32 _bet) external;

    /*
    @dev 1: side A is winner, 2: side B is winer
    */
    function setWinningSide(uint256 _winningSide) external returns(bool);

    /*
    @dev set winning side and settle all markets
    @dev 1: side A is winner, 2: side B is winer
    */
    function settle(uint256 _winningSide) external returns(bool);

    function cancel() external returns(bool);

    function cancelPlusPairs() external returns(bool);

    function stopNewBet() external returns(bool);

    function addBet(
        address _affiliate,
        uint256 _stake,
        uint256 _odds,
        uint256 _side,
        bool instant
    ) external returns(bytes32);

}