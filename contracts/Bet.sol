// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./interface/IBetPair.sol";
import "./interface/IBet.sol";
import "./interface/IWeb3BetsFO.sol";

contract Bet is IBet {
    address private w3bAddr;

    address public override better;

    address public override market;

    uint256 public override stake;

    uint256 public override matched;

    uint8 public override odds;

    address[] public betPairs;

    string  public override marketSide;

    IWeb3BetsFO private web3bets = IWeb3BetsFO(w3bAddr);

    constructor(
        address caller_,
        address market_,
        string memory marketSide_,
        uint256 stake_,
        uint8 odds_
    ) {
        require(msg.sender == web3bets.betFactory(), "only bet factory can create bet");
        market = market_;
        marketSide = marketSide_;
        stake = stake_;
        odds = odds_;
        better = caller_;
        matched = 0;

    }

    function getBetPairs() external view override returns (address[] memory){
        return betPairs;
    }


    function addPair(address _pairAddress) external override returns(bool) {
        require(msg.sender == market, "mkt only");
        betPairs.push(_pairAddress);
        return true;
    }

    function setMatched(uint _amount) external override returns(bool) {
        require(msg.sender == market, "mkt only");
        matched += _amount;
        return true;
    }
    
}