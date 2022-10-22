// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Market.sol";

contract Event is IEvent {
    address immutable private web3bets;
    address immutable public override owner;
    uint256 public override status;
    address[] private markets;

    modifier onlyOwner() {
        require(owner == msg.sender, "E1");
        _;
    }

    constructor(address owner_, address web3bets_)
    {
        owner = owner_;
        web3bets = web3bets_;
    }

    function getMarkets() external view override returns(address[] memory)
    {
        return markets;
    }

    function start() external override onlyOwner {
        require(status == 0, "E2");
        status = 1; // event live
        uint marketsLength = markets.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(markets[i]);
            market.stopNewBet();
        }
    }

    function end() external override onlyOwner {
        require(status != 3 && status != 2, "E3");
        uint marketsLength = markets.length;
        uint notSet;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(markets[i]);
            uint s = market.status();
            if(s == 0 || s == 4){
                notSet = 1;
                break;
            }
        }
        if(notSet != 1){
            status = 2; // event ended
        }
    }

    function cancel() external override onlyOwner {
        require(status != 3 && status != 2, "E4");
        status = 3; // event canceled
        uint marketsLength = markets.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(markets[i]);
            market.cancel();
        }
    }

    function createMarket() external override onlyOwner returns(address) {
        require(status == 0 || status == 1, "E5");
        Market market = new Market(web3bets);
        address marketAddress = address(market);
        markets.push(marketAddress);

        emit MarketCreated(address(this), marketAddress);
        return marketAddress;
    }

    function setMarketsWinners(Winner[] calldata _winners) external override onlyOwner {
        require(status == 0 || status == 1, "E6");
        uint marketsLength = _winners.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(_winners[i].market);
            market.setWinningSide(_winners[i].winningSide);
        }
    }

    function settleMarkets(Winner[] calldata _winners) external override onlyOwner {
        require(status == 0 || status == 1, "E7");
        uint marketsLength = _winners.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(_winners[i].market);

            market.settle(_winners[i].winningSide);
        }
    }

}