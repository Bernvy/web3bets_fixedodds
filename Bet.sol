// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./interface/IBet.sol";

import "./interface/IBetPair.sol";

contract Bet is IBet {
    address public override better;

    address public override marketAddress;

    string  public override marketSide;

    uint256 public override stake;

    uint8 public override odds;

    uint256 public override matched;

    address[] public betPairs;

    // modifier onlyEventOwner() {
    //     IEvent betEvent = IEvent(eventAddress);
    //     require(
    //         tx.origin == betEvent.getEventOwner(),
    //         "Only bet owners can apply this function"
    //     );

    //     _;
    // }

    modifier onlyBetter() {
        require(
            msg.sender == better,
            "Only event better can call this function"
        );
        _;
    }

    modifier onlyMarket() {
        require(
            msg.sender == marketAddress,
            "Only event better can call this function"
        );
        _;
    }

    constructor(
        address caller_,
        address marketAddress_,
        string memory marketSide_,
        uint256 stake_,
        uint8 odds_
    ) {
        marketAddress = marketAddress_;
        marketSide = marketSide_;
        stake = stake_;
        odds = odds_;
        better = caller_;
        matched = 0;

    }

    function getBetPairs() external view override returns (address[] memory){
        return betPairs;
    }

    function isValidBetPair(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        if(size > 0){
            IBetPair betPair = IBetPair(_addr);
            address pairMarketAddress = betPair.marketAddress();
            if(pairMarketAddress == this.marketAddress()){
                return true;
            }
            else{
                return false;
            }
        }
        else {
            return false;
        }
    }

    function addPair(address _pairAddress) external override onlyMarket returns(bool) {
        require(isValidBetPair(_pairAddress), "The address is not a valid betpair contract for this bet");
        betPairs.push(_pairAddress);
        return true;
    }

    function setMatched(uint _amount) external override onlyMarket returns(bool) {
        matched += _amount;
        return true;
    }
 
    function withdrawPending() external override onlyBetter {
        // require(address(this).balance > 0, "This bet has no funds");
        
    }
}