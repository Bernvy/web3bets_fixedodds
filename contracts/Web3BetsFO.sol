// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Market.sol";

/// @author Victor Okoro
/// @title Web3Bets Contract for FixedOdds decentralized betting exchange
/// @notice Contains Web3Bets ecosystem's variables and functions
/// @custom:security contact okoro.victor@web3bets.io

/**
* Copied and modified some codes from 
* https://github.com/wizardoma/web3_bets_contract/blob/main/contracts/Web3Bets.sol
*/

contract Web3BetsFO is IWeb3BetsFO {
    address public override contractOwner;
    address public override holdAddr = 0x602f6f6C93aC99008B9bc58ab8Ee61e7713aD43d;
    address public override ecoAddr = 0xBffe45D497Bde6f9809200f736084106d1d079df;
    /**
    * replace 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee with the
    * contract address of the stablecoin for the deployment network
    */
    address public override scAddr = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    uint256 public override vig = 10;
    uint256 public override hVig = 50;
    uint256 public override eVig = 25;
    uint256 public override aVig = 25;
    uint256 public override minStake = 1000000000000000000;
    bytes32[] private events;
    mapping(bytes32 => uint256) private eventsStatus;
    mapping(bytes32 => address) private eventOwners;
    mapping(bytes32 => address[]) private eventMarkets;
    mapping(address => address) private admins;
    mapping(address => address) private eventAdmins;
    mapping(address => address) private black;

    modifier onlyOwner
    {
        require(msg.sender == contractOwner,"W1");
        _;
    }

    modifier onlySystemAdmin
    {
        require(
            admins[msg.sender] != address(0) || msg.sender == contractOwner,
            "W2"
        );
        _;
    }

    modifier onlyEventAdmin
    {
        require(
            eventAdmins[msg.sender] != address(0) || msg.sender == contractOwner,
            "W3"
        );
        _;
    }

    event MarketCreated(bytes32 eventHash, address marketAddress);

    event EventCreated(bytes32 eventHash, address eventOwner);

    constructor()
    {
        contractOwner = msg.sender;
    }

    function isBlack(address _addr) external view override returns(bool)
    {
        if(black[_addr] == address(0)) {
            return false;
        }
        else {
            return true;
        }
    }

    function getEvents() external view override returns(bytes32[] memory)
    {
        return events;
    }

    function getEventStatus(bytes32 _event) external view override returns(uint256) 
    {
        return eventsStatus[_event];
    }

    function getEventOwner(bytes32 _event) external view override returns(address) 
    {
        return eventOwners[_event];
    }

    function getMarkets(bytes32 _event) external view override returns(address[] memory){
        return eventMarkets[_event];
    }

    function createEvent() external onlyEventAdmin returns(bytes32){
        bytes32 eventHash;
        uint i = 0;
        while(i >= 0){
            eventHash = keccak256(abi.encodePacked(
                msg.sender,
                events.length + 1 + i,
                block.timestamp,
                block.difficulty
            ));
            if(eventsStatus[eventHash] == 0){
                break;
            }
            i++;
        }
        eventsStatus[eventHash] = 1; // event started
        eventOwners[eventHash] = msg.sender; 
        events.push(eventHash);

        emit EventCreated(eventHash, msg.sender);
        return eventHash;
    }

    function createMarket(bytes32 _event) external onlyEventAdmin returns(address) {
        require(eventsStatus[_event] == 1 || eventsStatus[_event] == 4, "W4");
        Market market = new Market(_event);
        eventMarkets[_event].push(address(market));

        emit MarketCreated(_event, address(market));
        return address(market);
    }

    function setMarketsWinners(bytes32 _event, Struct.Winner[] calldata _winners) external {
        require(eventsStatus[_event] == 1 || eventsStatus[_event] == 4, "W5");
        uint marketsLength = _winners.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(_winners[i].market);
            market.setWinningSide(_winners[i].winningSide);
        }
        eventsStatus[_event] = 2; // event ended
    }

    function settleMarkets(bytes32 _event, Struct.Winner[] calldata _winners) external {
        require(eventsStatus[_event] == 1 || eventsStatus[_event] == 4, "W6");
        uint marketsLength = _winners.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(_winners[i].market);

            market.settle(_winners[i].winningSide);
        }
        eventsStatus[_event] = 2; // event ended
    }

    function startEvent(bytes32 _event) external onlyEventAdmin {
        require(eventsStatus[_event] == 1, "W7");
        address[] memory markets = eventMarkets[_event];
        eventsStatus[_event] = 4; // event live
        uint marketsLength = markets.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(markets[i]);
            market.stopNewBet();
        }
    }

    function cancelEvent(bytes32 _event) external onlyEventAdmin {
        require(eventsStatus[_event] != 3 && eventsStatus[_event] != 2, "W8");
        address[] memory markets = eventMarkets[_event];
        eventsStatus[_event] = 3; // event canceled
        uint marketsLength = markets.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(markets[i]);
            market.cancel();
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        contractOwner = newOwner;
    }
    
    function setAddrs(
        address _holdAddr,
        address _ecoAddr,
        address _scAddr
    ) 
        external onlySystemAdmin 
    {
        holdAddr = _holdAddr;
        ecoAddr = _ecoAddr;
        scAddr = _scAddr;
    }

    function setVig(uint256 _percent, uint _minStake) external onlySystemAdmin {
        require(
            _percent < 10,
            "W9"
        );
        vig = _percent;
        minStake = _minStake;
    }

    function setVigShare(
        uint256 _hVig,
        uint256 _eVig,
        uint256 _aVig
    ) external onlySystemAdmin {
        require(
            _hVig <= 100 && _eVig <= 100 && _aVig <= 100,
            "W10"
        );
        require(
            _hVig + _eVig + _aVig == 100,
            "W11"
        );

        hVig = _hVig;
        eVig = _eVig;
        aVig = _aVig;
    }
    
    function addSystemAdmin(address _addr)
        external
        onlyOwner
    {
        require(admins[_addr] == address(0), "W12");
        admins[_addr] = _addr;
    }

    function deleteSystemAdmin(address _systemAdmin)
        external
        onlyOwner
    {
        require (admins[_systemAdmin] != address(0), "W13");
        
        delete admins[_systemAdmin];
    }
    
    function addEventAdmin(address _addr)
        external
        onlySystemAdmin
    {
        require(eventAdmins[_addr] == address(0), "W14");

        eventAdmins[_addr] = _addr;
    }

    function deleteEventAdmin(address _eventOwner)
        external
        onlySystemAdmin 
    {
        require (eventAdmins[_eventOwner] != address(0), "W15");
        delete eventAdmins[_eventOwner];
    }
    
    function addBlacked(address _addr)
        external
        onlySystemAdmin
    {
        require(black[_addr] == address(0), "W16");
        black[_addr] = _addr;
    }

    function removeBlacked(address _addr) 
        external 
        onlySystemAdmin 
    {
        require (black[_addr] != address(0), "W17");
        delete black[_addr];
    }

}