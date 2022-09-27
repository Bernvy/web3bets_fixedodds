// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IBetPair {
    function market() external view returns(address);

    function sideABet() external view returns(address);

    function sideBBet() external view returns(address);

    function amountA() external view returns(uint);

    function amountB() external view returns(uint);

    function settled() external view returns(bool);

    function settle() external returns(bool);
}