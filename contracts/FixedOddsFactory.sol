// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Event.sol";
import "./Market.sol";
import "./Bet.sol";
import "./interface/IFixedOddsFactory.sol";
import "./interface/IWeb3BetsFO.sol";
import "./interface/IEvent.sol";
import "./interface/IMarket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FixedOddsFactory is IFixedOddsFactory {
    using SafeERC20 for IERC20;

    mapping (address => address[]) public userEvents;

    address[] public events;

    address private web3betsAddress;

    IWeb3BetsFO private web3bets = IWeb3BetsFO(web3betsAddress);

    IERC20 private _stableCoinWrapper = IERC20(web3bets.stableCoin());

    event EventCreated(address eventOwner, string name, address eventAddress);

    event MarketCreated(address marketAddress, address eventAddress, string marketName);

    constructor(address _web3betsAddress){
        web3betsAddress = _web3betsAddress;
    }

    function createEvent(
        string memory _name,
        uint _startTime,
        uint _minimumStake
    ) public override returns(address) {
        bool isEventAdmin = web3bets.isEventAdmin(msg.sender);
        require(isEventAdmin, "Only event admins can create events");
        Event wEvent = new Event(msg.sender, _name, _startTime, _minimumStake);
        
        userEvents[msg.sender].push(address(wEvent));
        events.push(address(wEvent));
        
        emit EventCreated(msg.sender, _name, address(wEvent));
        return address(wEvent);
    }

    function getEventsByOwner(address _account) public view override returns(address[] memory){
        return userEvents[_account];
    }

    function getEvents() public view override returns(address[] memory){
        return events;
    }

    function createMarket(string memory _name, address _eventAddress, string memory _sideAName,string memory _sideBName) public override returns(address) {
        
        IEvent _event = IEvent(_eventAddress);

        address _eventOwner = _event.getEventOwner();

        require(_eventOwner == msg.sender, "Only the event creator is allowed to add market the event");
        
        Market _market = new Market(_name, _eventAddress, _sideAName, _sideBName);

        _event.addMarket(address(_market));

        emit MarketCreated(address(_market), _eventAddress, _name);
        return address(_market);
    }

    function placeBet(address _marketAddress, string memory _marketSide, uint256 _stake, uint8 _odds)
        public override returns(address) 
    {
        _stake = _stake * 10 ** 18;
        _odds = _odds * 10 ** 2;
        _stableCoinWrapper.safeTransferFrom(msg.sender, _marketAddress, _stake);
        
        // create bet
        Bet _bet = new Bet(msg.sender, _marketAddress, _marketSide, _stake, _odds);

        // add to market
        IMarket _market = IMarket(_marketAddress);
        _market.addBet(msg.sender, address(_bet), _stake, _odds, _marketSide);

        // return bet address
        return address(_bet);
    }
}