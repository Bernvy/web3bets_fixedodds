// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IBetPair.sol";
import "./interface/IMarket.sol";
import "./interface/IBet.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BetPair is IBetPair {
    using SafeERC20 for IERC20;

    address public override marketAddress;

    address public override sideABetAddress;

    address public override sideBBetAddress;
    
    address public override winnerBet;

    address public override winnerAddress;

    uint public override amountA;

    uint public override amountB;

    IERC20 private _stableCoinWrapper;

    constructor (
        address marketAddress_,
        address sideABetAddress_,
        address sideBBetAddress_,
        uint amountA_,
        uint amountB_
    ) {
        marketAddress = marketAddress_;
        sideABetAddress = sideABetAddress_;
        sideBBetAddress = sideBBetAddress_;
        amountA = amountA_;
        amountB = amountB_;
    }

    function settlePair(address _stableCoin) external override {
        IMarket market = IMarket(marketAddress);
        require(market.hasSetWinningSide(), "Markets has not been settled");
        if(keccak256(abi.encodePacked(market.winningSide())) == keccak256(abi.encodePacked("sideA"))){
            winnerBet = sideABetAddress;
            IBet _winnerBet = IBet(winnerBet);
            winnerAddress = _winnerBet.better();

            _stableCoinWrapper = IERC20(_stableCoin);
            _stableCoinWrapper.safeTransferFrom(sideABetAddress, winnerAddress, amountA);
            _stableCoinWrapper.safeTransferFrom(sideBBetAddress, winnerAddress, amountB);
        }
        else if(keccak256(abi.encodePacked(market.winningSide())) == keccak256(abi.encodePacked("sideB"))){
            winnerBet = sideBBetAddress;
            IBet _winnerBet = IBet(winnerBet);
            winnerAddress = _winnerBet.better();

            _stableCoinWrapper = IERC20(_stableCoin);
            _stableCoinWrapper.safeTransferFrom(sideABetAddress, winnerAddress, amountA);
            _stableCoinWrapper.safeTransferFrom(sideBBetAddress, winnerAddress, amountB);
        }
    }
}