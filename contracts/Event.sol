// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IEvent.sol";
import "./interface/IMarket.sol";
import "./interface/IWeb3BetsFO.sol";

contract Event is IEvent {
    address private web3betsAddress;

    address public override eventOwner;

    uint256 public override startTime;

    uint256 public override minimumStake;

    uint constant MINIMUM_STAKE = 10 ** 18;

    address[] public markets;

    string public override name;

    EventStatus public override status;

    IWeb3BetsFO private web3bets = IWeb3BetsFO(web3betsAddress);

    modifier onlyFactory() {
        require(
            msg.sender == web3bets.eventFactory(),
            "owner o"
        );
        _;
    }

    constructor(
        address caller_,
        string memory eventTitle_,
        uint256 startTime_,
        uint256 minimumStake_
    ) {
        minimumStake_ *= 10 ** 18;
        require(msg.sender == web3bets.eventFactory(), "fty o");
        require( minimumStake_ >= MINIMUM_STAKE, "x min stake");
        name = eventTitle_;
        eventOwner = caller_;
        startTime = startTime_;
        minimumStake = minimumStake_;
        status = EventStatus.UPCOMING;
    }

    function getMarkets() external view override returns (address[] memory) {
        return markets;
    }

    function addMarket(address _marketAddress)
        external
        override
        returns(bool)
    {
        require(
            msg.sender == web3bets.marketFactory(),
            "owner o"
        );
        markets.push(_marketAddress);
        return true;
    }

    function updateName(string memory _eventTitle) external override onlyFactory returns(bool) 
    {
        name = _eventTitle;
        return true;
    }

    function cancelEvent() external override onlyFactory returns(bool) 
    {
        require (status != EventStatus.CANCELED, "xd event");
        require(status != EventStatus.ENDED, "ended event");

        for (uint256 i = 0; i < markets.length; i++) {
            IMarket market = IMarket(markets[i]);
            market.cancelMarket();
        }

        status = EventStatus.CANCELED;
        return true;
    }

    function postponeEvent(uint256 _startTime) external override onlyFactory  returns(bool) 
    {
        require (status != EventStatus.CANCELED, "xd event");
        require(status != EventStatus.ENDED, "ended event");

        startTime = _startTime;

        status = EventStatus.UPCOMING;
        return true;
    }

    function endEvent() external override onlyFactory  returns(bool) {
        require (status != EventStatus.CANCELED, "xd event");
        require(status != EventStatus.ENDED, "ended event");

        bool allMarketsAreSettled = true;
        for (uint256 i = 0; i < markets.length; i++) {
            IMarket market = IMarket(markets[i]);
            if (!market.hasSetWinningSide()) {
                allMarketsAreSettled = false;
                break;
            }
        }

        require(allMarketsAreSettled, "all mkt nt settled");
        status = EventStatus.ENDED;
        return true;
    }

    function startEvent() external override onlyFactory returns(bool) 
    {
        require (status != EventStatus.CANCELED, "xd event");
        require(status != EventStatus.ENDED, "ended event");
        require (status != EventStatus.STARTED, "already live");
        if (status == EventStatus.UPCOMING) {
            status = EventStatus.STARTED;
        } else {
            revert("err: bad status");
        }
        return true;
    }
}