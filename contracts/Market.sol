// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IMarket.sol";
import "./interface/IWeb3BetsFO.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Market is IMarket, ReentrancyGuard {
    address immutable public override factory;
    /*
    @dev stores the hash of all bets
    */
    bytes32[] private pairs;
    /*
    @dev stores the hash of all bets
    */
    bytes32[] private bets;
    /*
    @dev stores the hash of all pending bets
    */
    bytes32[] private pendingBets;
    /*
    @dev status of a market, 0: active, 1: sideA wins, 2: side B wins, 3: canceled
    */
    uint8 public override status = 0;
    struct MarketPair {
        bytes32 betHashA;
        bytes32 betHashB;
        uint256 amountA;
        uint256 amountB;
        bool settled;
    }
    mapping(address => uint256) private bal;
    mapping(bytes32 => MarketBet) private betsInfo;
    mapping(address => bytes32[]) private userBets;
    mapping(bytes32 => MarketPair) private pairsInfo;
    mapping(bytes32 => bytes32) private betsPair;
    IERC20 immutable public token;

    modifier onlyFactory() {
        require(
            msg.sender == factory,
            "owner o"
        );
        _;
    }

    event BetCreated(
        address better,
        address marketAddr,
        bytes32 hash,
        uint256 stake,
        uint256 odds,
        uint8 side
    );

    event PairCreated(
        bytes32 betHashA,
        bytes32 betHashB,
        uint256 amountA,
        uint256 amountB
    );

    constructor() {
        factory = msg.sender;
        token = IERC20(IWeb3BetsFO(factory).scAddr());
    }

    function getBalance(address _user) external view override returns(uint256) {
        return bal[_user];
    }

    function getUserBets(address _user) external view override returns(MarketBet[] memory) {
        MarketBet[] memory _userBets;
        bytes32[] memory _bets = userBets[_user];
        for(uint i = 0; i < bets.length; i++){
            _userBets[i] = betsInfo[_bets[i]];
        }
        return _userBets;
    }

    function withdraw(address _addr) external nonReentrant returns(bool) {
        uint256 availAmount = bal[_addr];
        require(token.balanceOf(address(this)) > availAmount && availAmount > 0, "< fund");
        bool success = token.transfer(_addr, availAmount);
        require(success, "Tx Failed");
        bal[_addr] -= availAmount;
        return true;
    } 
 
    function cancelPending(bytes32 _bet) external override nonReentrant {
        MarketBet memory bet = betsInfo[_bet];
        require(msg.sender == bet.better, "bet owner only");
        uint remStake = bet.stake - bet.matched;
        bal[bet.better] = remStake;
        betsInfo[_bet].matched = bet.stake;
        // remove from pending bets
        for(uint i = 0; i < pendingBets.length; i++){
            if(pendingBets[i] == _bet) {
                delete pendingBets[i];
            }
        }
    }
    
    function settlePair(bytes32 _pair) public override nonReentrant returns(bool) {
        require(!pairsInfo[_pair].settled, "already settled");
        require(status == 1 || status == 2, "win not set");
        address winner;
        address affiliate;
        uint256 winAmount;
        uint256 vigAmount;
        IWeb3BetsFO app = IWeb3BetsFO(factory);
        if(status == 1){
            winner = betsInfo[pairsInfo[_pair].betHashA].better;
            winAmount = pairsInfo[_pair].amountA + (pairsInfo[_pair].amountB * (100 - app.vig()) / 100);
            vigAmount = pairsInfo[_pair].amountB * app.vig() / 100;
            affiliate = betsInfo[pairsInfo[_pair].betHashA].affiliate;
        }
        else if(status == 2){
            winner = betsInfo[pairsInfo[_pair].betHashB].better;
            winAmount = pairsInfo[_pair].amountB + (pairsInfo[_pair].amountA * (100 - app.vig()) / 100);
            vigAmount = pairsInfo[_pair].amountA * app.vig() / 100;
            affiliate = betsInfo[pairsInfo[_pair].betHashB].affiliate;
        }
        else{
            revert("x win");
        }
        if(affiliate == address(0x0)){
            affiliate = app.ecoAddr();
        }
        bal[winner] += winAmount;
        bal[app.holdAddr()] += vigAmount * app.hVig() / 100;
        bal[app.ecoAddr()] += vigAmount * app.eVig() / 100;
        bal[affiliate] += vigAmount * app.aVig() / 100;
        pairsInfo[_pair].settled = true;
        return true;
    }

    function setWinningSide(uint8 _winningSide)
        external
        onlyFactory
        returns(bool)
    {
        require (status == 0 && (_winningSide == 1 || _winningSide == 2), "!x win");
        status = _winningSide;
        return true;
    }

    function cancelMarket() external override onlyFactory returns(bool) 
    { 
        require(status == 0);
        for(uint i = 0; i < pairs.length; i++){
            settlePair(pairs[i]);
        }
        status = 3;
        return true;
    }

    function addBet(
        address _better,
        address _affiliate,
        uint256 _stake,
        uint256 _odds,
        uint8 _side,
        bool _instant
    ) 
    external
    onlyFactory
    returns(bytes32)
    {
        require(_side == 1 || _side == 2, "invalid side");
        bytes32 betHash = _createBet(_better, _affiliate, _stake, 0, _odds, _side);
        // _odds is the odds the better inputed which represents the min odds they want to receive
        // (_odds * 100) / (_odds - 100) is the complement of _odds, it represents the max odds the better offer to pay
        if(pendingBets.length > 0){
            uint _remStake = _stake;
            while(_remStake >= 1 * 10 ** 18){
                uint selectedIndex = 0;
                uint256 maxOdds = 0;
                for(uint i = 0; i < pendingBets.length; i++){
                    bytes32 pBet = pendingBets[i];
                    if(_side == betsInfo[pBet].side){
                        continue;
                    }
                    if(betsInfo[pBet].odds>maxOdds){
                        maxOdds = betsInfo[pBet].odds;
                        selectedIndex = i;
                    }
                }
                if(maxOdds > _odds || _instant) {
                    bytes32 selectedHash = pendingBets[selectedIndex];
                    MarketBet memory selectedBet = betsInfo[selectedHash];
                    uint offeredStake = (selectedBet.stake - selectedBet.matched) / (_odds - 1);
                    uint betterAmount;
                    uint makerAmount;
                    bytes32 pairHash;
                    if(offeredStake <= _stake) {
                        betterAmount = offeredStake;
                        makerAmount = offeredStake * (_odds - 1);
                        if(_side == 1){
                            pairHash = _createPair(betHash,selectedHash,betterAmount,makerAmount);
                            emit PairCreated(betHash,selectedHash,betterAmount,makerAmount);
                        }
                        else if(_side == 2){
                            pairHash = _createPair(selectedHash,betHash,makerAmount,betterAmount);
                            emit PairCreated(selectedHash,betHash,makerAmount,betterAmount);
                        }
                        betsPair[betHash] = pairHash;
                        betsPair[selectedHash] = pairHash;
                    }
                    else {
                        betterAmount = _stake;
                        makerAmount = _stake * (_odds - 1);
                        if(_side == 1){
                            pairHash = _createPair(betHash,selectedHash,betterAmount,makerAmount);
                            emit PairCreated(betHash,selectedHash,betterAmount,makerAmount);
                        }
                        else if(_side == 2){
                            pairHash = _createPair(selectedHash,betHash,makerAmount,betterAmount);
                            emit PairCreated(selectedHash,betHash,makerAmount,betterAmount);
                        }
                    }
                    betsInfo[betHash].matched += betterAmount;
                    betsInfo[selectedHash].matched += makerAmount;
                    if(betsInfo[selectedHash].stake - betsInfo[selectedHash].matched == 0) {
                        delete pendingBets[selectedIndex];
                    }

                    _remStake -= betterAmount;
                }
                else {
                    pendingBets.push(betHash);
                    break;
                }
            }
        }
        else {
            pendingBets.push(betHash);
        }
        emit BetCreated(msg.sender, address(this), betHash, _stake, _odds, _side);
        return betHash;
    }

    function _createBet(
        address _better,
        address _affiliate,
        uint256 _stake,
        uint256 _matched,
        uint256 _odds,
        uint8 _side
    )
    private
    returns(bytes32)
    {
        bytes32 betHash;
        while(true){
            betHash = keccak256(abi.encodePacked(
                _better,
                address(this),
                bets.length,
                block.timestamp,
                block.difficulty
            ));
            if(betsInfo[betHash].stake == 0){
                break;
            }
        }
        betsInfo[betHash] = MarketBet(_better, _affiliate, _stake, _matched, _odds, _side);
        bets.push(betHash);
        userBets[_better].push(betHash);
        return betHash;
    }

    function _createPair(
        bytes32 _betHashA,
        bytes32 _betHashB,
        uint256 _amountA,
        uint256 _amountB
    ) 
    private
    returns(bytes32)
    {
        bytes32 pairHash;
        while(true){
            pairHash = keccak256(abi.encodePacked(
                _betHashA,
                _betHashB,
                pairs.length,
                block.timestamp,
                block.difficulty
            ));
            if(pairsInfo[pairHash].amountA == 0){
                break;
            }
        }
        pairsInfo[pairHash] = MarketPair(_betHashA, _betHashB, _amountA, _amountB, false);
        pairs.push(pairHash);
        return pairHash;
    }
    
}