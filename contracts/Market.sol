// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IMarket.sol";
import "./interface/IWeb3BetsFO.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Market is IMarket, ReentrancyGuard {
    address private owner;
    address private factory;
    /*
    @dev status of a market, 0: active, 1: sideA wins, 2: side B wins, 3: canceled, 4: stop
    */
    uint256 public override status = 0;
    /*
    @dev stores the hash of all bets
    */
    bytes32[] private pairs;
    /*
    @dev stores the hash of all bets
    */
    bytes32[] private bets;
    
    mapping(address => uint256) private bal;
    mapping(bytes32 => Struct.MarketBet) private betsInfo;
    mapping(address => bytes32[]) private userBets;
    mapping(bytes32 => Struct.MarketPair) private pairsInfo;
    mapping(bytes32 => bytes32[]) private betPairs;
    IERC20 immutable private token;
    IWeb3BetsFO immutable private app = IWeb3BetsFO(factory);

    modifier onlyFactory() {
        require(
            msg.sender == owner 
            || 
            msg.sender == app.contractOwner()
            ||
            msg.sender == factory,
            "caller not authorized"
        );
        _;
    }

    event Withdraw(
        address beneficiary,
        uint256 value
    );

    event BetCreated(
        address better,
        address marketAddr,
        bytes32 hash,
        uint256 stake,
        uint256 odds,
        uint256 side
    );

    constructor(address owner_) {
        owner = owner_;
        factory = msg.sender;
        token = IERC20(IWeb3BetsFO(factory).scAddr());
    }

    function getBalance(address _user) external view override returns(uint256) {
        return bal[_user];
    }

    function getUserBets(address _user) 
        external view override returns(Struct.MarketBet[] memory) 
    {
        Struct.MarketBet[] memory _userBets;
        bytes32[] memory _bets = userBets[_user];
        uint betsLength = bets.length;
        for(uint i = 0; i < betsLength; i++){
            _userBets[i] = betsInfo[_bets[i]];
        }
        return _userBets;
    }

    function withdraw(address _addr) public override nonReentrant returns(bool) {
        uint256 availAmount = bal[_addr];
        require(
            token.balanceOf(address(this)) >= availAmount && availAmount > 0,
            "zero value available"
        );
        bal[_addr] -= availAmount;
        bool success = token.transfer(_addr, availAmount);
        require(success, "transfer to caller failed");

        emit Withdraw(_addr, availAmount);
        return true;
    } 
 
    function withdrawPending(bytes32 _bet) public override {
        Struct.MarketBet memory bet = betsInfo[_bet];
        require(msg.sender == bet.better, "unauthorized caller");
        uint remStake = bet.stake - bet.matched;
        bal[bet.better] += remStake;
        betsInfo[_bet].matched = bet.stake;
        if(bal[msg.sender] > 0){
            withdraw(msg.sender);
        }
    }

    function cancelBet(bytes32 _bet) external override {
        require(msg.sender == betsInfo[_bet].better, "unauthorized caller");
        if(status == 0){
            _cancelBetPairs(_bet);
        }
        withdrawPending(_bet);
    }

    function settleBet(bytes32 _bet) external override {
        bytes32[] memory _pairs = betPairs[_bet];
        uint pairsLength = _pairs.length;
        for(uint i = 0; i < pairsLength; i++){
            _settlePair(_pairs[i]);
        }
        if(bal[msg.sender] > 0){
            withdraw(msg.sender);
        }
    }

    function setWinningSide(uint256 _winningSide)
        public
        override
        onlyFactory
        returns(bool)
    {
        if((status == 0 || status == 4) && (_winningSide == 1 || _winningSide == 2)){
            status = _winningSide;
            return true;
        }
        else {
            return false;
        }
        
    }

    function settle(uint256 _winningSide)
        external
        override
        onlyFactory
        returns(bool)
    {
        if(setWinningSide(_winningSide)){
            uint pairsLength = pairs.length;
            for(uint i = 0; i < pairsLength; i++){
                _settlePair(pairs[i]);
            }
            return true;
        }
        else {
            return false;
        }
        
    }

    function cancel() external override onlyFactory returns(bool) 
    { 
        if(status == 0 || status == 4){
            uint pairsLength = pairs.length;
            for(uint i = 0; i < pairsLength; i++){
                _cancelPair(pairs[i]);
            }
            status = 3;
            return true;
        }
        else {
            return false;
        }
    }

    function start() external override onlyFactory returns(bool){
        if(status == 0){
            status = 4;
            return true;
        }
        else {
            return false;
        }
    }

    function addBet(
        address _better,
        address _affiliate,
        uint256 _stake,
        uint256 _odds,
        uint256 _side,
        bool _instant
    ) 
    external
    override
    returns(bytes32)
    {
        require(!app.isBlack(msg.sender), "blacklist");
        require(status == 0, "market not active");
        require(_side == 1 || _side == 2, "invalid side");
        require(token.balanceOf(msg.sender) >= _stake,"not enough token balalnce");
        require(token.allowance(msg.sender, address(this)) >= _stake,"not enough allowance");
        require(_stake >= app.minStake(),"less than min stake");
        require(
            token.transferFrom(msg.sender, address(this), _stake),
            "transfer from caller failed"
        );
        bytes32 betHash = _createBet(
            _better,
            _affiliate,
            _stake,
            0,
            (_odds * 100) / (_odds - 100),
            _side
        );
        // _odds is the odds the better inputed which represents the min odds they want to receive
        // (_odds * 100) / (_odds - 100) is the complement of _odds, it represents the max odds - 
        // the better offer to pay
        if(bets.length > 0){
            uint _remStake = _stake;
            uint256 betsLength = bets.length;
            while(_remStake >= app.minStake()){
                uint selectedIndex = 0;
                uint256 maxOdds = 0;
                for(uint i = 0; i < betsLength; i++){
                    bytes32 bet = bets[i];
                    if(_side == betsInfo[bet].side){
                        continue;
                    }
                    if(betsInfo[bet].odds > maxOdds){
                        maxOdds = betsInfo[bet].odds;
                        selectedIndex = i;
                    }
                }
                uint256 betterAmount = 0;
                if(maxOdds > _odds || (maxOdds > 0 && _instant)) {
                    bytes32 selectedHash = bets[selectedIndex];
                    Struct.MarketBet memory selectedBet = betsInfo[selectedHash];
                    uint offeredStake = (selectedBet.stake - selectedBet.matched) / (_odds - 100);
                    offeredStake *= 100;
                    
                    betterAmount = _match(_stake, offeredStake, _odds, _side, betHash, selectedHash);
                }
                else {
                    break;
                }
                _remStake -= betterAmount;
            }
        }
        emit BetCreated(msg.sender, address(this), betHash, _stake, _odds, _side);
        return betHash;
    }

    function _match(
        uint256 _stake,
        uint256 _offeredStake,
        uint256 _odds,
        uint256 _side,
        bytes32 _betHash,
        bytes32 _selectedHash
    ) private returns (uint256)
    {
        uint256 betterAmount;
        uint256 makerAmount;
        bytes32 pairHash;
        if(_offeredStake <= _stake) {
            betterAmount = _offeredStake;
            makerAmount = _offeredStake * (_odds - 100);
            makerAmount /= 100;
            if(_side == 1){
                pairHash = _createPair(_betHash,_selectedHash,betterAmount,makerAmount);
            }
            else if(_side == 2){
                pairHash = _createPair(_selectedHash,_betHash,makerAmount,betterAmount);
            }
        }
        else {
            betterAmount = _stake;
            makerAmount = _stake * (_odds - 100);
            makerAmount /= 100;
            if(_side == 1){
                pairHash = _createPair(_betHash,_selectedHash,betterAmount,makerAmount);
            }
            else if(_side == 2){
                pairHash = _createPair(_selectedHash,_betHash,makerAmount,betterAmount);
            }
        }
        betPairs[_betHash].push(pairHash);
        betPairs[_selectedHash].push(pairHash);
        betsInfo[_betHash].matched += betterAmount;
        betsInfo[_selectedHash].matched += makerAmount;
        return betterAmount;
    }

    function _cancelBetPairs(bytes32 _bet) private returns(bool) {
        Struct.MarketBet memory bet = betsInfo[_bet];
        bytes32[] memory _pairs = betPairs[_bet];
        uint pairsLength = _pairs.length;
        for(uint i = 0; i < pairsLength; i++){
            bytes32 counterBetHash;
            uint256 counterAmount;
            uint256 thisAmount;
            address counterBetter;
            if(bet.side == 1) {
                thisAmount = pairsInfo[_pairs[i]].amountA;
                counterBetHash = pairsInfo[_pairs[i]].betHashB;
                counterAmount = pairsInfo[_pairs[i]].amountB;
            }
            else if(bet.side == 2) {
                thisAmount = pairsInfo[_pairs[i]].amountB;
                counterBetHash = pairsInfo[_pairs[i]].betHashA;
                counterAmount = pairsInfo[_pairs[i]].amountA;
            }
            counterBetter = betsInfo[counterBetHash].better;
            bal[bet.better] += thisAmount * (100 - app.vig()) / 100;
            betsInfo[counterBetHash].matched -= counterAmount;
            uint256 vigAmount = thisAmount * app.vig() / 100;
            bal[app.holdAddr()] += vigAmount * app.hVig() / 100;
            bal[app.ecoAddr()] += vigAmount * app.eVig() / 100;
            bal[bet.affiliate] += vigAmount * app.aVig() / 100;
            pairsInfo[_pairs[i]].settled = true;
        }
        return true;
    }

    function _cancelPair(bytes32 _pair) private {
        address betterA = betsInfo[pairsInfo[_pair].betHashA].better;
        address betterB = betsInfo[pairsInfo[_pair].betHashB].better;
        bal[betterA] += pairsInfo[_pair].amountA;
        bal[betterB] += pairsInfo[_pair].amountB;
        pairsInfo[_pair].settled = true;
        return;
    }
    
    function _settlePair(bytes32 _pair) private nonReentrant returns(bool) {
        if(pairsInfo[_pair].settled){
            return false;
        }
        address winner;
        address affiliate;
        uint256 winAmount;
        uint256 vigAmount;
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
            return false;
        }
        bal[winner] += winAmount;
        bal[app.holdAddr()] += vigAmount * app.hVig() / 100;
        bal[app.ecoAddr()] += vigAmount * app.eVig() / 100;
        bal[affiliate] += vigAmount * app.aVig() / 100;
        pairsInfo[_pair].settled = true;
        return true;
    }

    function _createBet(
        address _better,
        address _affiliate,
        uint256 _stake,
        uint256 _matched,
        uint256 _odds,
        uint256 _side
    )
    private
    returns(bytes32)
    {
        bytes32 betHash;
        uint i = 0;
        while(i >= 0){
            betHash = keccak256(abi.encodePacked(
                _better,
                address(this),
                bets.length + 1 + i,
                block.timestamp,
                block.difficulty
            ));
            if(betsInfo[betHash].stake == 0){
                break;
            }
            i++;
        }
        if(_affiliate == address(0)){
            _affiliate = app.ecoAddr();
        }
        betsInfo[betHash] = Struct.MarketBet(_better, _affiliate, _stake, _matched, _odds, _side);
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
        uint i = 0;
        while(i >= 0){
            pairHash = keccak256(abi.encodePacked(
                _betHashA,
                _betHashB,
                pairs.length + 1 + i,
                block.timestamp,
                block.difficulty
            ));
            if(pairsInfo[pairHash].amountA == 0){
                break;
            }
            i++;
        }
        pairsInfo[pairHash] = Struct.MarketPair(_betHashA, _betHashB, _amountA, _amountB, false);
        pairs.push(pairHash);
        return pairHash;
    }
    
}