// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IEvent.sol";

import "./interface/IMarket.sol";

import "./Market.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

// import "./library/DataType.sol";

contract Event is IEvent {
    address public eventOwner;

    uint256 public startTime;

    uint256 public minimumStake;

    address[] public markets;

    uint constant MINIMUM_STAKE = 1;

    string public name;

    EventStatus public status;

    modifier onlyOwner() {
        require(
            msg.sender == eventOwner,
            "Event operations only applicable to owner"
        );
        _;
    }

    constructor(
        address caller_,
        string memory eventTitle_,
        uint256 startTime_,
        uint256 minimumStake_
    ) {
        require(minimumStake_ >= MINIMUM_STAKE, "Minimum stake for creating an event must be greater than 10000000000 wei");
        name = eventTitle_;
        eventOwner = caller_;
        startTime = startTime_;
        minimumStake = minimumStake_;
        status = EventStatus.UPCOMING;
    }

    function getName() public view override returns (string memory) {
        return name;
    }

    function isValidMarket(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        if(size > 0){
            IMarket market = IMarket(_addr);
            address marketEventAddress = market.eventAddress();
            if(marketEventAddress == address(this)){
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

    function addMarket(address _marketAddress)
        external
        override
        onlyOwner returns(bool)
    {
        require(isValidMarket(_marketAddress), "The address is not a valid market contract for this event");
        markets.push(_marketAddress);
        return true;
    }

    function updateName(string memory _eventTitle) external override onlyOwner  returns(bool) {
        name = _eventTitle;
        return true;
    }

    function cancelEvent() external override onlyOwner  returns(bool) {
        if (status == EventStatus.CANCELED) {
            revert("Event already canceled");
        } else if (status == EventStatus.ENDED) {
            revert("Event already ended");
        }

        for (uint256 i = 0; i < markets.length; i++) {
            IMarket market = IMarket(markets[i]);
            market.cancelMarket();
        }

        status = EventStatus.CANCELED;
        return true;
    }

    function postponeEvent(uint256 _startTime) external override onlyOwner  returns(bool) {
        if (status == EventStatus.CANCELED) {
            revert("Event already canceled");
        } else if (status == EventStatus.ENDED) {
            revert("Event already ended");
        }

        startTime = _startTime;

        status = EventStatus.UPCOMING;
        return true;
    }

    function getMarkets() external view override returns (address[] memory) {
        return markets;
    }

    function getMinimumStake() external view override returns (uint256) {
        return minimumStake;
    }

    function getCount() internal view returns (uint256 count) {
        return markets.length;
    }

    function getEventOwner() external view override returns (address) {
        return eventOwner;
    }

    function endEvent() external override onlyOwner  returns(bool) {
        if (status == EventStatus.CANCELED) {
            revert("Canceled event can not be ended");
        } else if (status == EventStatus.ENDED) {
            revert("Event already ended");
        }

        bool allMarketsAreSettled = true;
        for (uint256 i = 0; i < markets.length; i++) {
            IMarket market = IMarket(markets[i]);
            if (!market.hasSetWinningSide()) {
                allMarketsAreSettled = false;
                break;
            }
        }

        if (!allMarketsAreSettled) {
            revert(
                "You must set winning side in all markets before ending event"
            );
        } else {
            status = EventStatus.ENDED;
        }
        return true;
    }

    function startEvent() external onlyOwner  returns(bool) {
        if (status == EventStatus.CANCELED) {
            revert("Canceled event can not be started");
        } else if (status == EventStatus.ENDED) {
            revert("Ended event can not be started");
        } else if (status == EventStatus.STARTED) {
            revert("Event already started");
        } else if (status == EventStatus.UPCOMING) {
            status = EventStatus.STARTED;
        } else {
            revert("An error occurred starting event");
        }
        return true;
    }

    function getEventStatus() external view override returns (EventStatus) {
        return status;
    }
}