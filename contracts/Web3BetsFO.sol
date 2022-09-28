// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IWeb3BetsFO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author Victor Okoro
/// @title Web3Bets Contract for FixedOdds decentralized betting exchange
/// @notice Contains Web3Bets ecosystem's variables and functions
/// @custom:security contact okoro.victor@web3bets.io

/* 
copied and modified code logic from github Repo: https://github.com/wizardoma/web3_bets_contract.git
*/
contract Web3BetsFO is IWeb3BetsFO {

    address public contractOwner;
    
    address public override ecosystemAddress;
    address public override holdersAddress;
    address public override stableCoin;

    address public override eventFactory;
    address public override marketFactory;
    address public override betFactory;

    uint256 public override holdersVig = 50;
    uint256 public override ecosystemVig = 50;
    uint256 public override vigPercentage = 10;

    address[] public systemAdmins;
    address[] public eventAdmins;
    address[] public blackList;

    mapping(address => address) public admins;
    mapping(address => address) public eventOwners;
    mapping(address => address) public blacked;

    IERC20 private _stableCoinWrapper = IERC20(stableCoin);

    modifier onlyUser() {
        require(
            msg.sender == contractOwner,
            "You have no privilege to run this function"
        );
        _;
    }
    modifier onlySystemAdmin {
        require(
            isSystemAdmin(msg.sender) || msg.sender == contractOwner,
            "You have no privilege to run this function"
        );
        _;
    }
    modifier uniqueSystemAdmin(address _addr) {
        require(admins[_addr] == address(0), "already a system admin");
        _;
    }
    modifier uniqueEventAdmin(address _addr) {
        require(eventOwners[_addr] == address(0), "already an event admin");
        _;
    }
    modifier uniqueBlack(address _addr) {
        require(blacked[_addr] == address(0), "already in blacklist");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }
    
    function setAddresses(address holdAddr, address ecoAddr,address scAddr) external onlySystemAdmin {
        holdersAddress = holdAddr;
        ecosystemAddress = ecoAddr;
        stableCoin = scAddr;
    }

    function setFactory(address _event,address _market,address _bet) external onlySystemAdmin {
        eventFactory = _event;
        marketFactory = _market;
        betFactory = _bet;
    }

    function setVigPercentage(uint256 _percentage) external onlySystemAdmin {
        require(
            _percentage < 10,
            "Vig percentage must be expressed in 0 to 10 percentage. Example: 6"
        );
        vigPercentage = _percentage;
    }

    function setVigPercentageShares(
        uint256 hVig,
        uint256 eVig
    ) external onlySystemAdmin {
        require(
            hVig <= 100 && eVig <= 100,
            "Vig percentages shares must be expressed in a  0 to 100 ratio. Example: 30"
        );
        require(
            hVig + eVig  == 100,
            "The sum of all Vig percentage shares must be equal to 100"
        );

        holdersVig = hVig;
        ecosystemVig = eVig;
    }

    function shareBetEarnings() external override {
        uint256 _vigAmount = _stableCoinWrapper.balanceOf(address(this));
        require(_vigAmount > 0, "bet earnings must be greater than 0");
        uint256 holdersShare = (_vigAmount * holdersVig )/ 100;
        require(holdersShare > 0, "holders' share must be greater than 0");
        uint256 ecosystemShare = (_vigAmount * ecosystemVig) / 100;
        require(ecosystemShare > 0, "ecosystem share must be greater than 0");

        _stableCoinWrapper.transfer(ecosystemAddress, ecosystemShare);

        _stableCoinWrapper.transfer(holdersAddress, holdersShare);
    }
    
    function addSystemAdmin(address _addr)
        external
        onlyUser
        uniqueSystemAdmin(_addr)
    {
        systemAdmins.push(_addr);
        admins[_addr] = _addr;
    }

    function deleteSystemAdmin(address _systemAdmin) external onlyUser {
        require (admins[_systemAdmin] != address(0), "Invalid event owner");
        
        delete admins[_systemAdmin];

        for (uint256 i = 0; i < systemAdmins.length; i++) {
            if (systemAdmins[i] == _systemAdmin) {
                delete systemAdmins[i];
                break;
            }
        }
    }
    
    function addEventAdmin(address _addr)
        external
        onlySystemAdmin
        uniqueEventAdmin(_addr)
    {
        require(holdersAddress == address(0) || ecosystemAddress == address(0), "you must set holders and ecosystmeAddress addresses before adding event owners");

        eventAdmins.push(_addr);
        eventOwners[_addr] = _addr;
    }

    function deleteEventAdmin(address _eventOwner) external onlySystemAdmin {
        require (eventOwners[_eventOwner] != address(0), "Invalid event owner");
        
        delete eventOwners[_eventOwner];

        for (uint256 i = 0; i < eventAdmins.length; i++) {
            if (eventAdmins[i] == _eventOwner) {
                delete eventAdmins[i];
                break;
            }
        }
    }
    
    function addBlacked(address _addr)
        external
        onlySystemAdmin
        uniqueBlack(_addr)
    {
        eventAdmins.push(_addr);
        eventOwners[_addr] = _addr;
    }

    function removeBlacked(address _eventOwner) external onlySystemAdmin {
        require (blacked[_eventOwner] != address(0), "Invalid event owner");
        
        delete blacked[_eventOwner];

        for (uint256 i = 0; i < blackList.length; i++) {
            if (blackList[i] == _eventOwner) {
                delete blackList[i];
                break;
            }
        }
    }

    function isSystemAdmin(address _addr) public view override returns (bool) {
        if(admins[_addr] != address(0)){
            bool found = false;
            for (uint256 i = 0; i < systemAdmins.length; i++) {
                if (systemAdmins[i] == _addr) {
                    found = true;
                    break;
                }
            }
            return found;
        }
        else{
            return false;
        }
    }

    function isEventAdmin(address _addr) public view override returns (bool) {
        if(eventOwners[_addr] != address(0)){
            bool found = false;
            for (uint256 i = 0; i < eventAdmins.length; i++) {
                if (eventAdmins[i] == _addr) {
                    found = true;
                    break;
                }
            }
            return found;
        }
        else{
            return false;
        }
    }

    function isBlack(address _addr) public view override returns (bool) {
        if(blacked[_addr] != address(0)){
            bool found = false;
            for (uint256 i = 0; i < blackList.length; i++) {
                if (blackList[i] == _addr) {
                    found = true;
                    break;
                }
            }
            return found;
        }
        else{
            return false;
        }
    }

}