// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IMarket.sol";
import "./interface/IBet.sol";
import "./BetPair.sol";
import "./interface/IWeb3BetsFO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Market is IMarket {

    address private web3betsAddress;

    string public override name;
    address public override eventAddress;
    bool public override hasSetWinningSide = false;
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

    IWeb3BetsFO private web3bets = IWeb3BetsFO(web3betsAddress);

    address private stableCoin = web3bets.stableCoin();

    IERC20 private _stableCoinWrapper = IERC20(stableCoin);

    modifier onlyFactory() {
        require(
            msg.sender == web3bets.marketFactory(),
            "owner o"
        );
        _;
    }

    modifier onlyBetFactory() {
        require(
            msg.sender == web3bets.betFactory(),
            "owner o"
        );
        _;
    }

    constructor(
        string memory name_,
        address eventAddress_,
        string memory sideAName_,
        string memory sideBName_
    ) {
        require(msg.sender == web3bets.marketFactory(), "fty o");
        name = name_;
        eventAddress = eventAddress_;
        sideAName = sideAName_;
        sideBName = sideBName_;
    }
 
    function withdrawPending(address _bet) external override onlyFactory returns(bool){
        IBet bet = IBet(_bet);
        uint remStake = bet.stake() - bet.matched();
        require(address(this).balance > remStake, "0 fund");
        _stableCoinWrapper.transfer( bet.better(), remStake);
        bet.setMatched(remStake);
        return true;
    }
    
    function settlePair(address _pair) external override onlyFactory returns(bool) {
        IBetPair pair = IBetPair(_pair);
        address _pairAddr = pair.market();
        address _sideABet = pair.sideABet();
        address _sideBBet = pair.sideBBet();
        uint _amountA = pair.amountA();
        uint _amountB = pair.amountB();
        IMarket market = IMarket(_pairAddr);
        require(!pair.settled(), "pair already settled");
        require(market.hasSetWinningSide(), "win not set");
        if(keccak256(abi.encodePacked(market.winningSide())) == keccak256(abi.encodePacked("sideA"))){
            _stableCoinWrapper.transfer(_sideABet, _amountA + (_amountB * 9 / 10) );
            _stableCoinWrapper.transfer(web3betsAddress, _amountB / 10);
            pair.settle();
        }
        else if(keccak256(abi.encodePacked(market.winningSide())) == keccak256(abi.encodePacked("sideB"))){
            _stableCoinWrapper.transfer(_sideBBet, _amountB + (_amountA * 9 / 10) );
            _stableCoinWrapper.transfer(web3betsAddress, _amountA / 10);
            pair.settle();
        }
        else{
            revert("x win");
        }
        return true;
    }

    function setWinningSide(string memory _winningSide)
        external
        override onlyFactory
        returns(bool)
    {
        require (hasSetWinningSide != true, "!x win");
        winningSide = _winningSide;
        hasSetWinningSide = true;
        return true;
    }

    function upadteMarket(string memory _name, string memory _sideAName, string memory _sideBName)
        external
        override onlyFactory returns(bool)
    {
        name = _name;
        sideAName = _sideAName;
        sideBName = _sideBName;
        return true;
    }

    function cancelMarket() external override onlyFactory returns(bool) 
    { 
        if (isCanceled) {
            return true;
        }
        isCanceled = true;
        return true;
    }


    function addBet(address _better, address _betAddress, uint256 _stake, uint8 _odds, string memory _side, bool _instant)
        external override onlyBetFactory returns(bool)
    {   
        if(keccak256(abi.encodePacked(_side)) == keccak256(abi.encodePacked("sideA"))){
            _addToSideA(_better, _betAddress, _stake, _odds);
            _matchSideABet(_betAddress,_stake,_odds,_instant);
        }
        else if (keccak256(abi.encodePacked(_side)) == keccak256(abi.encodePacked("sideB"))) {
            _addToSideB(_better, _betAddress, _stake, _odds);
            _matchSideBBet(_betAddress,_stake,_odds,_instant);
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

    function _matchSideABet(address _betAddress, uint256 _stake, uint8 _odds, bool _instant)
        internal
    {
        // _odds is the odds the better inputed which represents the min odds they want to receive
        // (_odds * 100) / (_odds - 100) is the complement of _odds, it represents the max odds the better offer to pay
        if(sideBBetsPending.length > 0){
            uint _remStake = _stake;
            while(_remStake >= 1 * 10 ** 18){
                uint selectedIndex = 0;
                uint8 maxOdds = 0;
                for(uint i = 0; i < sideBBetsPending.length; i++){
                    MarketBet memory bet = sideBBetsPending[i];
                    if(bet.odds>maxOdds){
                        maxOdds = bet.odds;
                        selectedIndex = i;
                    }
                }
                if(maxOdds > _odds || _instant) {
                    MarketBet memory selectedBet = sideBBetsPending[selectedIndex];
                    IBet selectedBetInstance = IBet(selectedBet.betAddress);
                    uint matchedSelectedBet = selectedBetInstance.matched();
                    uint offeredStake = (selectedBet.stake - matchedSelectedBet) / (_odds - 1);
                    uint _amountA;
                    uint _amountB;
                    if(offeredStake <= _stake) {
                        _amountA = offeredStake;
                        _amountB = offeredStake * (_odds - 1);
                    }
                    else {
                        _amountA = _stake;
                        _amountB = _stake * (_odds - 1);
                    }
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
                    sideABetsPending.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: (_odds * 100) / (_odds - 100)}));
                    break;
                }
            }
        }
        else {
            sideABetsPending.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: (_odds * 100) / (_odds - 100)}));
        }
        return;
    }

    function _matchSideBBet(address _betAddress, uint256 _stake, uint8 _odds, bool _instant)
        internal
    {
        // _odds is the odds the better inputed which represents the min odds they want to receive
        // (_odds * 100) / (_odds - 100) is the complement of _odds, it represents the max odds the better offer to pay
        if(sideABetsPending.length > 0){
            uint _remStake = _stake;
            while(_remStake >= 1 * 10 ** 18){
                uint selectedIndex = 0;
                uint8 maxOdds = 0;
                for(uint i = 0; i < sideABetsPending.length; i++){
                    MarketBet memory bet = sideABetsPending[i];
                    if(bet.odds>maxOdds){
                        maxOdds = bet.odds;
                        selectedIndex = i;
                    }
                }
                if(maxOdds >= _odds || _instant) {
                    MarketBet memory selectedBet = sideABetsPending[selectedIndex];
                    IBet selectedBetInstance = IBet(selectedBet.betAddress);
                    uint matchedSelectedBet = selectedBetInstance.matched();
                    uint offeredStake = (selectedBet.stake - matchedSelectedBet) / (_odds - 1);
                    uint _amountA;
                    uint _amountB;
                    if(offeredStake <= _stake) {
                        _amountB = offeredStake;
                        _amountA = offeredStake * (_odds - 1);
                    }
                    else {
                        _amountB = _stake;
                        _amountA = _stake * (_odds - 1);
                    }
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
                    sideBBetsPending.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: (_odds * 100) / (_odds - 100)}));
                    break;
                }
            }
        }
        else {
            sideBBetsPending.push(MarketBet({betAddress: _betAddress, stake: _stake, odds: (_odds * 100) / (_odds - 100)}));
        }
        return;
    }
}