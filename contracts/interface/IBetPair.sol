// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IBetPair {
    function marketAddress() external view returns(address);

    function sideABetAddress() external view returns(address);

    function sideBBetAddress() external view returns(address);

    function winnerBet() external view returns(address);

    function winnerAddress() external view returns(address);

    function amountA() external view returns(uint);

    function amountB() external view returns(uint);

    function settlePair(address _stableCoin) external;
}