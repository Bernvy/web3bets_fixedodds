// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Struct {

    struct App {
        address holdAddr;
        address ecoAddr;
        uint256 minStake;
        uint256 vig;
        uint256 aVig;
        uint256 eVig;
        uint256 hVig;
    }

    struct MarketBet {
        address better;
        address affiliate;
        uint256 stake;
        uint256 matched;
        uint256 odds;
        uint256 side;
    }
    
    struct MarketPair {
        uint256 betIdA;
        uint256 betIdB;
        uint256 amountA;
        uint256 amountB;
        bool settled;
    }
}