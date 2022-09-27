// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./Market.sol";
import "./interface/IEvent.sol";
import "./interface/IMarketFactory.sol";

contract MarketFactory is IMarketFactory {
    using SafeERC20 for IERC20;

    address private web3betsAddress;

    IWeb3BetsFO private web3bets = IWeb3BetsFO(web3betsAddress);

    address private stableCoin = web3bets.stableCoin();

    IERC20 private _stableCoinWrapper = IERC20(stableCoin);

    constructor(address _web3bets){
        web3betsAddress = _web3bets;
    }

    function createMarket(string memory _name, address _eventAddress, string memory _sideAName,string memory _sideBName) public override returns(address) {
        
        IEvent _event = IEvent(_eventAddress);

        address _eventOwner = _event.eventOwner();

        require(_eventOwner == msg.sender, "o e own");
        
        Market _market = new Market(_name, _eventAddress, _sideAName, _sideBName);

        _event.addMarket(address(_market));

        emit MarketCreated(address(_market), _eventAddress, _name);
        return address(_market);
    }

    function withdraw(address _betAddr) external override returns(bool)
    {
        IBet _bet = IBet(_betAddr);
        IMarket _market = IMarket(_bet.market());
        return _market.withdrawPending(_betAddr);
    }

    function settle(address _pairAddr) public override returns(bool)
    {
        IBetPair _bet = IBetPair(_pairAddr);
        IMarket _market = IMarket(_bet.market());
        return _market.settlePair(_pairAddr);
    }

    function settleBet(address _betAddr) external override returns(bool) {
        IBet _bet = IBet(_betAddr);
        address[] memory pairs = _bet.getBetPairs();
        for(uint i = 0; i < pairs.length; i++){
            settle(pairs[i]);
        }
        return true;
    }

    function setWinner(address _marketAddr, string memory _side) external override returns(bool)
    {
        IMarket _market = IMarket(_marketAddr);
        IEvent _event = IEvent(_market.eventAddress());
        require(msg.sender == _event.eventOwner(), "only evt owner can manage mkt");
        return _market.setWinningSide(_side);
    }

    function update(address _marketAddr, string memory _name, string memory _sideAName, string memory _sideBName) external override returns(bool)
    {
        IMarket _market = IMarket(_marketAddr);
        IEvent _event = IEvent(_market.eventAddress());
        require(msg.sender == _event.eventOwner(), "only evt owner can manage mkt");
        return _market.upadteMarket(_name,_sideAName,_sideBName);
    }

    function cancel(address _marketAddr) external override returns(bool)
    {
        IMarket _market = IMarket(_marketAddr);
        IEvent _event = IEvent(_market.eventAddress());
        require(msg.sender == _event.eventOwner(), "only evt owner can manage mkt");
        return _market.cancelMarket();
    }

}