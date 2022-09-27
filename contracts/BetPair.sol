// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IBetPair.sol";
import "./interface/IBet.sol";
import "./interface/IWeb3BetsFO.sol";

contract BetPair is IBetPair {

    address private w3bAddr;

    address public override market;

    address public override sideABet;

    address public override sideBBet;

    uint public override amountA;

    uint public override amountB;

    bool public override settled = false;

    IWeb3BetsFO private web3bets = IWeb3BetsFO(w3bAddr);

    constructor (
        address market_,
        address sideABet_,
        address sideBBet_,
        uint amountA_,
        uint amountB_
    ) {
        require(msg.sender == web3bets.marketFactory(), "only market factory can match bets");
        market = market_;
        sideABet = sideABet_;
        sideBBet = sideBBet_;
        amountA = amountA_;
        amountB = amountB_;
    }

    function settle() external override returns(bool){
        require(msg.sender == market, "mkt only");
        settled = true;
        return true;
    }
    
}