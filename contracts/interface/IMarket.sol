// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMarket{
    struct MarketBet {
        address better;
        address affiliate;
        uint256 stake;
        uint256 matched;
        uint256 odds;
        uint8 side;
    }

    function factory() external view returns (address);

    function status() external view returns (uint8);

    function token() external view returns (IERC20);

    function getBalance(address _user) external view returns(uint256);

    function getUserBets(address _user) external view returns(MarketBet[] memory);

    function withdraw(address _address) external returns(bool);

    function cancelPending(bytes32 _bet) external;

    function settlePair(bytes32 _pairHash) external returns(bool);
    /*
    @dev 1: side A is winner, 2: side B is winer
    */
    function setWinningSide(uint8 _winningSide) external returns(bool);

    function cancelMarket() external returns(bool);

    function addBet(
        address _better,
        address _affiliate,
        uint256 _stake,
        uint256 _odds,
        uint8 _side,
        bool instant
    ) external returns(bytes32);

}