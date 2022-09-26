// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library DataType {
    enum EventStatus {
        UPCOMING,
        STARTED,
        ENDED,
        CANCELED
    }

    enum MarketStatus {
        PENDING,
        FINISHED
    }

    struct Bet {
        uint256 betId;
        address owner;
        address eventAddress;
        address market;
        address pool;
    }

    struct Event {
        uint256 id;
        string title;
        string description;
        uint256 canceledTime;
        uint256 createdTime;
        uint256 endedTime;
        uint256 minimumStake;
        EventStatus status;
    }

    struct Pool {
        uint256 id;
        string name;
        string description;
    }

    struct Market {
        uint256 id;
        string name;
        string description;
        MarketStatus status;
    }
}