// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IEvent.sol";

import "./interface/IMarket.sol";

import "./interface/IBet.sol";

import "./BetPair.sol";

contract Market is IMarket {

    string public name;
    address public override eventAddress;
    bool public override hasSetWinningSide;
    string public override winningSide;
    bool public override isCanceled = false;

    string public override sideAName;
    uint256 public override sideATotalStake = 0;
    string public override sideBName;
    uint256 public override sideBTotalStake = 0;

    struct MarketBet {
        address betAddress;
        uint256 stake;
        uint8 odds;
    }
    MarketBet[] public sideABets;
    MarketBet[] private sideABetsPending;
    MarketBet[] public sideBBets;
    MarketBet[] private sideBBetsPending;

    mapping(address => uint256) public sideAUsersStakes;
    mapping(address => uint256) public sideBUsersStakes;

    modifier onlyEventOwner() {
        IEvent marketEvent = IEvent(eventAddress);
        address eventOwner = marketEvent.getEventOwner();
        require(msg.sender == eventOwner, "Only event owners set winning pool");
        _;
    }

    constructor(
        string memory name_,
        address eventAddress_,
        string memory sideAName_,
        string memory sideBName_
    ) {
        name = name_;
        eventAddress = eventAddress_;
        sideAName = sideAName_;
        sideBName = sideBName_;
    }

    function upadteMarket( string memory name_, string memory sideAName_, string memory sideBName_)
        external
        override returns(bool)
    {
        name = name_;
        sideAName = sideAName_;
        sideBName = sideBName_;
        return true;
    }

    function isValidBet(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        if(size > 0){
            IBet bet = IBet(_addr);
            address betMarketAddress = bet.marketAddress();
            if(betMarketAddress == address(this)){
                return true;
            }
            else{
                return false;
            }
        }
        else {
            return false;
        }
    }

    function addBet(address _better, address _betAddress, uint256 _stake, uint8 _odds, string memory _side)
        external override returns(bool)
    {
        require(isValidBet(_betAddress), "The address is not a valid bet contract for this market");
        if(keccak256(abi.encodePacked(_side)) == keccak256(abi.encodePacked("sideA"))){
            _addToSideA(_better, _betAddress, _stake, _odds);
            _matchSideABet(_betAddress,_stake,_odds);
        }
        else if (keccak256(abi.encodePacked(_side)) == keccak256(abi.encodePacked("sideB"))) {
            _addToSideB(_better, _betAddress, _stake, _odds);
            _matchSideBBet(_betAddress,_stake,_odds);
        }
        return true;
    }

    function _addToSideA(address _better, address _betAddress, uint256 _stake, uint8 _odds)
        internal
    {
        sideATotalStake += _stake;
        sideABets.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: _odds}));
        sideAUsersStakes[_better] += _stake;
        return;
    }

    function _addToSideB(address _better, address _betAddress, uint256 _stake, uint8 _odds)
        internal
    {
        sideBTotalStake += _stake;
        sideBBets.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: _odds}));
        sideBUsersStakes[_better] += _stake;
        return;
    }

    function _matchSideABet(address _betAddress, uint256 _stake, uint8 _odds)
        internal
    {
        uint betCount = sideBBetsPending.length;
        if(betCount > 0){
            uint _remStake = _stake;
            while(_remStake >= 1 * 10 ** 18){
                uint selectedIndex = 0;
                uint8 maxOdds = 0;
                for(uint i = 0; i < betCount; i++){
                    MarketBet memory bet = sideBBetsPending[i];
                    if(bet.odds>maxOdds){
                        maxOdds = bet.odds;
                        selectedIndex = i;
                    }
                }
                if(maxOdds > _odds) {
                    MarketBet memory selectedBet = sideBBetsPending[selectedIndex];
                    IBet selectedBetInstance = IBet(selectedBet.betAddress);
                    uint matchedSelectedBet = selectedBetInstance.matched();
                    uint offeredStake = (selectedBet.stake - matchedSelectedBet) * (_odds - 100) / 100 ;
                    uint _amountA;
                    if(offeredStake > _stake) {
                        _amountA = _stake;
                    }
                    else {
                        _amountA = offeredStake;
                    }
                    uint _amountB = _amountA * _odds;
                    BetPair _pair = new BetPair(address(this),_betAddress,selectedBet.betAddress,_amountA,_amountB);
                    delete sideBBetsPending[selectedIndex];

                    IBet _betA = IBet(_betAddress);
                    _betA.setMatched(_amountA);
                    _betA.addPair(address(_pair));

                    IBet _betB = IBet(selectedBet.betAddress);
                    _betB.setMatched(_amountB);
                    _betB.addPair(address(_pair));

                    _remStake -= _amountA;
                }
                else {
                    sideABetsPending.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: _odds}));
                    break;
                }
            }
        }
        else {
            sideABetsPending.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: _odds}));
        }
        return;
    }

    function _matchSideBBet(address _betAddress, uint256 _stake, uint8 _odds)
        internal
    {
        uint betCount = sideABetsPending.length;
        if(betCount > 0){
            uint _remStake = _stake;
            while(_remStake >= 1 * 10 ** 18){
                uint selectedIndex = 0;
                uint8 maxOdds = 0;
                for(uint i = 0; i < betCount; i++){
                    MarketBet memory bet = sideABetsPending[i];
                    if(bet.odds>maxOdds){
                        maxOdds = bet.odds;
                        selectedIndex = i;
                    }
                }
                if(maxOdds > _odds) {
                    MarketBet memory selectedBet = sideABetsPending[selectedIndex];
                    IBet selectedBetInstance = IBet(selectedBet.betAddress);
                    uint matchedSelectedBet = selectedBetInstance.matched();
                    uint offeredStake = (selectedBet.stake - matchedSelectedBet) * (_odds - 100) / 100 ;
                    uint _amountB;
                    if(offeredStake > _stake) {
                        _amountB = _stake;
                    }
                    else {
                        _amountB = offeredStake;
                    }
                    uint _amountA = _amountB * _odds;
                    BetPair _pair = new BetPair(address(this), selectedBet.betAddress, _betAddress, _amountA, _amountB);
                    delete sideABetsPending[selectedIndex];

                    IBet _betB = IBet(_betAddress);
                    _betB.setMatched(_amountB);
                    _betB.addPair(address(_pair));

                    IBet _betA = IBet(selectedBet.betAddress);
                    _betA.setMatched(_amountA);
                    _betA.addPair(address(_pair));

                    _remStake -= _amountA;
                }
                else {
                    sideBBetsPending.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: _odds}));
                    break;
                }
            }
        }
        else {
            sideBBetsPending.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: _odds}));
        }
        return;
    }

    // move this function to Factory
    function setWinningSide(string memory _winningSide)
        external
        override
        onlyEventOwner returns(bool)
    {
        if (hasSetWinningSide == true) {
            revert("Winning Pool already set");
        }
        winningSide = _winningSide;
        hasSetWinningSide = true;

        if (!hasSetWinningSide) {
            revert("No Pool Address was found");
        } else {
            return true;
        }
    }

    function getEventName() external override returns (string memory) {
        IEvent marketEvent = IEvent(eventAddress);
        return marketEvent.getName();
    }

    function getName() external view override returns (string memory) {
        return name;
    }

    function cancelMarket() external override returns(bool) {
        if (isCanceled) {
            return true;
        }
        isCanceled = true;
        return true;
    }
}