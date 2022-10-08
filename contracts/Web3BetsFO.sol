// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Market.sol";

/// @author Victor Okoro
/// @title Web3Bets Contract for FixedOdds decentralized betting exchange
/// @notice Contains Web3Bets ecosystem's variables and functions
/// @custom:security contact okoro.victor@web3bets.io

/* 
copied and modified code logic from github Repo: https://github.com/wizardoma/web3_bets_contract.git
*/
contract Web3BetsFO is IWeb3BetsFO {
    address public contractOwner;
    address public override holdAddr = 0x602f6f6C93aC99008B9bc58ab8Ee61e7713aD43d;
    address public override ecoAddr = 0x602f6f6C93aC99008B9bc58ab8Ee61e7713aD43d;
    address public override scAddr = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    uint256 public override vig = 10;
    uint256 public override hVig = 50;
    uint256 public override eVig = 50;
    uint256 public override aVig = 25;
    mapping(address => address) public admins;
    mapping(address => address) public eventOwners;
    mapping(address => address) public black;

    modifier onlyOwner {
        require(msg.sender == contractOwner,"crt own o");
        _;
    }

    modifier onlySystemAdmin {
        require(
            admins[msg.sender] != address(0) || msg.sender == contractOwner,
            "sys adm o"
        );
        _;
    }

    event MarketCreated(address marketAddress);

    constructor() {
        contractOwner = msg.sender;
    }

    function isBlack(address _addr) external view returns(bool){
        if(black[_addr] == address(0)) {
            return false;
        }
        else {
            return true;
        }
    }

    function createMarket() external onlySystemAdmin returns(address) {
        Market market = new Market();
        emit MarketCreated(address(market));
        return address(market);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        contractOwner = newOwner;
    }
    
    function setAddrs(address _holdAddr, address _ecoAddr,address _scAddr) external onlySystemAdmin {
        holdAddr = _holdAddr;
        ecoAddr = _ecoAddr;
        scAddr = _scAddr;
    }

    function setVigPercentage(uint256 _percent) external onlySystemAdmin {
        require(
            _percent < 100,
            "vig <100"
        );
        vig = _percent;
    }

    function setVigShare(
        uint256 _hVig,
        uint256 _eVig,
        uint256 _aVig
    ) external onlySystemAdmin {
        require(
            _hVig <= 100 && _eVig <= 100 && _aVig <= 100,
            "h,e <100"
        );
        require(
            _hVig + _eVig + _aVig == 100,
            "h+e+a =100"
        );

        hVig = _hVig;
        eVig = _eVig;
        aVig = _aVig;
    }
    
    function addSystemAdmin(address _addr)
        external
        onlyOwner
    {
        require(admins[_addr] == address(0), "alr sys adm");
        admins[_addr] = _addr;
    }

    function deleteSystemAdmin(address _systemAdmin)
        external
        onlyOwner
    {
        require(msg.sender == contractOwner,"crt own o");
        require (admins[_systemAdmin] != address(0), "x evt own");
        
        delete admins[_systemAdmin];
    }
    
    function addEventAdmin(address _addr)
        external
        onlySystemAdmin
    {
        require(eventOwners[_addr] == address(0), "alr evt adm");

        eventOwners[_addr] = _addr;
    }

    function deleteEventAdmin(address _eventOwner) external onlySystemAdmin {
        require (eventOwners[_eventOwner] != address(0), "x evt own");
        
        delete eventOwners[_eventOwner];
    }
    
    function addBlacked(address _addr)
        external
        onlySystemAdmin
    {
        require(black[_addr] == address(0), "alr xst");
        eventOwners[_addr] = _addr;
    }

    function removeBlacked(address _addr) external onlySystemAdmin {
        require (black[_addr] != address(0), "x evt own");
        
        delete black[_addr];
    }

}