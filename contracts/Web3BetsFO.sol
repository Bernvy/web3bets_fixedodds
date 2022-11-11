// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./EventFactory.sol";

/// @author Victor Okoro
/// @title Web3Bets Contract for FixedOdds decentralized betting exchange
/// @notice Contains Web3Bets ecosystem's variables and functions
/// @custom:security contact okoro.victor@web3bets.io

/**
* Copied and modified some codes from 
* https://github.com/wizardoma/web3_bets_contract/blob/main/contracts/Web3Bets.sol
*/

contract Web3BetsFO is IWeb3BetsFO {
    uint256 public override vig = 10;
    uint256 public override hVig = 50;
    uint256 public override eVig = 30;
    uint256 public override aVig = 20;
    uint256 public override minStake = 1 * 10 ** 18;
    address public override holdAddr = 0x602f6f6C93aC99008B9bc58ab8Ee61e7713aD43d;
    address public override ecoAddr = 0xBffe45D497Bde6f9809200f736084106d1d079df;
    /**
    * replace 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1 with the
    * contract address of the stablecoin for the deployment network
    */
    address public override scAddr = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1;
    address private contractOwner;
    mapping(address => address) private admins;
    mapping(address => address) private eventAdmins;
    mapping(address => address) private black;
    address[] eventFactories;

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
    
    function isEventAdmin(address _addr) external view override returns(bool)
    {
        if(eventAdmins[_addr] == address(0)) {
            return false;
        }
        else {
            return true;
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
            "W3"
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
            "W4"
        );
        require(
            _hVig + _eVig + _aVig == 100,
            "W5"
        );

        hVig = _hVig;
        eVig = _eVig;
        aVig = _aVig;
    }
    
    function addSystemAdmin(address _addr)
        external
        onlyOwner
    {
        require(admins[_addr] == address(0), "W6");
        admins[_addr] = _addr;
    }

    function deleteSystemAdmin(address _systemAdmin)
        external
        onlyOwner
    {
        require (admins[_systemAdmin] != address(0), "W7");
        
        delete admins[_systemAdmin];
    }
    
    function addEventAdmin(address _addr)
        external
        onlySystemAdmin
    {
        require(eventAdmins[_addr] == address(0), "W8");

        eventAdmins[_addr] = _addr;
    }

    function deleteEventAdmin(address _eventOwner)
        external
        onlySystemAdmin 
    {
        require (eventAdmins[_eventOwner] != address(0), "W9");
        delete eventAdmins[_eventOwner];
    }
    
    function addBlacked(address _addr)
        external
        onlySystemAdmin
    {
        require(black[_addr] == address(0), "W10");
        black[_addr] = _addr;
    }

    function removeBlacked(address _addr) 
        external 
        onlySystemAdmin 
    {
        require (black[_addr] != address(0), "W11");
        delete black[_addr];
    }

    function deployEventFactory() external onlyOwner returns(address)
    {
        EventFactory eventFactory = new EventFactory();
        address factoryAddress = address(eventFactory);
        eventFactories.push(factoryAddress);

        emit FactoryCreated(factoryAddress);
        return factoryAddress;
    }

}