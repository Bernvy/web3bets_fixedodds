// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Struct {
    struct MarketPair {
        bytes32 betHashA;
        bytes32 betHashB;
        uint256 amountA;
        uint256 amountB;
        bool settled;
    }

    struct MarketBet {
        address better;
        address affiliate;
        uint256 stake;
        uint256 matched;
        uint256 odds;
        uint256 side;
    }

    struct Winner {
        address market;
        uint winningSide;
    }
}