// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Struct {
    struct App {
        bytes32 eventHash;
        address factory;
        address eventOwner;
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
        bytes32 betHashA;
        bytes32 betHashB;
        uint256 amountA;
        uint256 amountB;
        bool settled;
    }

    struct Winner {
        address market;
        uint winningSide;
    }
}