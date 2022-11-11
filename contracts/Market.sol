// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IMarket.sol";
import "./interface/IEvent.sol";
import "./interface/IWeb3BetsFO.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Market is IMarket, ReentrancyGuard {
    address immutable private factory = msg.sender;
    IERC20 immutable private token;
    IWeb3BetsFO private app;
    Struct.App private a;
    /*
    @dev status of a market, 0: active, 1: sideA wins, 2: side B wins, 3: canceled, 4: no new bet
    */
    uint256 public override status;
    mapping(address => uint256) private bal;
    /*
    @dev stores the hash of all bets
    */
    uint256[] private bets;
    mapping(address => uint256[]) private userBets;
    mapping(uint256 => Struct.MarketBet) private betsInfo;
    /*
    @dev stores the hash of all bets
    */
    uint256[] private pairs;
    mapping(uint256 => uint256[]) private betPairs;
    mapping(uint256 => Struct.MarketPair) private pairsInfo;
    

    modifier notBlack() {
        require(!app.isBlack(msg.sender), "M1");
        _;
    }
    modifier onlyFactory() {
        require(
            msg.sender == factory || msg.sender == IEvent(factory).owner(),
            "M2"
        );
        _;
    }

    constructor(address web3bets_) {
        app = IWeb3BetsFO(web3bets_);
        a = Struct.App(
            app.holdAddr(),
            app.ecoAddr(),
            app.minStake(),
            app.vig(),
            app.aVig(),
            app.eVig(),
            app.hVig()
        );
        token = IERC20(app.scAddr());
    }

    /**
    * @dev Returns the amount of tokens owned by `_user` in this market.
    */
    function getBalance(address _user) external view override returns(uint256) {
        return bal[_user];
    }

    /**
    * @dev Returns hash IDs of all the bets placed by `_user`.
    */
    function getUserBets(address _user) 
        external view override returns(uint256[] memory) 
    {
        return userBets[_user];
    }

    /**
    * @dev Returns details of `_bet`.
    */
    function getBets() external view override returns(uint256[] memory) 
    {
        return bets;
    }

    /**
    * @dev Returns details of `_bet`.
    */
    function getBet(uint256 _bet) 
        external view override returns(Struct.MarketBet memory) 
    {
        return betsInfo[_bet];
    }

    /**
    * @dev Returns hash IDs of all the bets placed by `_user`.
    */
    function getBetPairs(uint256 _bet) 
        external view override returns(uint256[] memory) 
    {
        return betPairs[_bet];
    }

    /**
    * @dev Returns details of `_bet`.
    */
    function getPairs() external view override returns(uint256[] memory) 
    {
        return pairs;
    }

    /**
    * @dev Returns details of `_bet`.
    */
    function getPair(uint256 _pair) external view override returns(Struct.MarketPair memory) 
    {
        return pairsInfo[_pair];
    }

    /**
    * @dev transfer bal[`_user`] to `_user`, bal
    */
    function withdraw(address _user) public override nonReentrant returns(bool) {
        require(
            token.balanceOf(address(this)) >= bal[_user] && bal[_user] > 0,
            "M3"
        );
        uint256 availAmount = bal[_user];
        bal[_user] = 0;
        bool success = token.transfer(_user, availAmount);
        require(success, "M4");

        emit Withdraw(_user, availAmount);
        return true;
    } 
 
    /**
    * @dev refund all unmatched stake in `_bet`, and withraw for caller address
    */
    function withdrawPending(uint256 _bet) public override {
        Struct.MarketBet memory bet = betsInfo[_bet];
        require(msg.sender == bet.better, "M5");
        uint remStake = bet.stake - bet.matched;
        bal[bet.better] += remStake;
        betsInfo[_bet].matched = bet.stake;
        if(bal[msg.sender] > 0){
            withdraw(msg.sender);
        }
    }

    /**
    * @dev cancel all pairs in `_bet`, 
    */
    function cancelBet(uint256 _bet) external override {
        require(msg.sender == betsInfo[_bet].better, "M6");
        if(status == 0 || status == 3){
            _cancelBetPairs(_bet);
        }
        withdrawPending(_bet);
    }

    /**
    * @dev settle all pairs in `_bet`, 
    */
    function settleBet(uint256 _bet) external override {
        uint256[] memory _pairs = betPairs[_bet];
        uint pairsLength = _pairs.length;
        for(uint i = 0; i < pairsLength; i++){
            _settlePair(_pairs[i]);
        }
        if(bal[msg.sender] > 0){
            withdraw(msg.sender);
        }
    }

    /**
    * @dev assign `_winningSide` to `status` 
    */
    function setWinningSide(uint256 _winningSide)
        public
        override
        onlyFactory
        returns(bool)
    {
        if(
            (status == 0 || status == 1 || status == 2 || status == 4)
            &&
            (_winningSide == 1 || _winningSide == 2)
        )
        {
            status = _winningSide;
            return true;
        }
        else {
            return false;
        }
        
    }

    /**
    * @dev assign `_winningSide` to `status` 
    */
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
            status = 3;
            return true;
        }
        else {
            return false;
        }
    }

    function cancelPlusPairs() external override onlyFactory returns(bool) 
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

    function stopNewBet() external override onlyFactory returns(bool){
        if(status == 0){
            status = 4;
            return true;
        }
        else {
            return false;
        }
    }

    function addBet(
        address _affiliate,
        uint256 _stake,
        uint256 _odds,
        uint256 _side,
        bool _instant
    ) 
    external
    override
    notBlack
    {
        require(status == 0, "M7");
        require(_side == 1 || _side == 2, "M8");
        require(token.balanceOf(msg.sender) >= _stake,"M9");
        require(token.allowance(msg.sender, address(this)) >= _stake,"M10");
        require(_stake >= a.minStake,"M11");
        require(
            token.transferFrom(msg.sender, address(this), _stake),
            "M12"
        );
        uint256 betId = _createBet(
            msg.sender,
            _affiliate,
            _stake,
            0,
            (_odds * 100) / (_odds - 100),
            _side
        );
        emit BetCreated(msg.sender, address(this), betId, _stake, _odds, _side);
        // _odds is the odds the better inputed which represents the min odds they want to receive
        // (_odds * 100) / (_odds - 100) is the complement of _odds, it represents the max odds - 
        // the better offer to pay
        if(bets.length > 0){
            uint256 betsLength = bets.length;
            while(_stake >= a.minStake){
                uint selectedIndex = 0;
                uint256 maxOdds = 0;
                for(uint i = 0; i < betsLength; i++){
                    uint256 bet = bets[i];
                    if(_side == betsInfo[bet].side){
                        continue;
                    }
                    if(msg.sender == betsInfo[bet].better){
                        continue;
                    }
                    if(betsInfo[bet].odds > maxOdds){
                        maxOdds = betsInfo[bet].odds;
                        selectedIndex = i;
                    }
                }
                uint256 betterAmount = 0;
                if(maxOdds >= _odds || (maxOdds > 0 && _instant)) {
                    Struct.MarketBet memory selectedBet = betsInfo[bets[selectedIndex]];
                    uint offeredStake = (selectedBet.stake - selectedBet.matched) / (_odds - 100);
                    offeredStake *= 100;
                    
                    betterAmount = _match(_stake, offeredStake, _odds, _side, betId, bets[selectedIndex]);
                }
                else {
                    break;
                }
                _stake -= betterAmount;
            }
        }
    }

    function _match(
        uint256 _stake,
        uint256 _offeredStake,
        uint256 _odds,
        uint256 _side,
        uint256 _betId,
        uint256 _selectedId
    ) private returns (uint256)
    {
        uint256 betterAmount;
        uint256 makerAmount;
        uint256 pairId;
        if(_offeredStake <= _stake) {
            betterAmount = _offeredStake;
            makerAmount = _offeredStake * (_odds - 100);
            makerAmount /= 100;
            if(_side == 1){
                pairId = _createPair(_betId,_selectedId,betterAmount,makerAmount);
            }
            else if(_side == 2){
                pairId = _createPair(_selectedId,_betId,makerAmount,betterAmount);
            }
        }
        else {
            betterAmount = _stake;
            makerAmount = _stake * (_odds - 100);
            makerAmount /= 100;
            if(_side == 1){
                pairId = _createPair(_betId,_selectedId,betterAmount,makerAmount);
            }
            else if(_side == 2){
                pairId = _createPair(_selectedId,_betId,makerAmount,betterAmount);
            }
        }
        betPairs[_betId].push(pairId);
        betPairs[_selectedId].push(pairId);
        betsInfo[_betId].matched += betterAmount;
        betsInfo[_selectedId].matched += makerAmount;
        return betterAmount;
    }

    function _cancelBetPairs(uint256 _bet) private returns(bool) {
        Struct.MarketBet memory bet = betsInfo[_bet];
        uint256[] memory _pairs = betPairs[_bet];
        uint pairsLength = _pairs.length;
        for(uint i = 0; i < pairsLength; i++){
            if(pairsInfo[_pairs[i]].settled){
                continue;
            }
            uint256 counterBetHash;
            uint256 counterAmount;
            uint256 thisAmount;
            address counterBetter;
            if(bet.side == 1) {
                thisAmount = pairsInfo[_pairs[i]].amountA;
                counterBetHash = pairsInfo[_pairs[i]].betIdB;
                counterAmount = pairsInfo[_pairs[i]].amountB;
            }
            else if(bet.side == 2) {
                thisAmount = pairsInfo[_pairs[i]].amountB;
                counterBetHash = pairsInfo[_pairs[i]].betIdA;
                counterAmount = pairsInfo[_pairs[i]].amountA;
            }
            counterBetter = betsInfo[counterBetHash].better;
            bal[bet.better] += thisAmount * (100 - a.vig) / 100;
            betsInfo[counterBetHash].matched -= counterAmount;
            uint256 vigAmount = thisAmount * a.vig / 100;
            bal[a.holdAddr] += vigAmount * a.hVig / 100;
            bal[a.ecoAddr] += vigAmount * a.eVig / 100;
            bal[bet.affiliate] += vigAmount * a.aVig / 100;
            pairsInfo[_pairs[i]].settled = true;
        }
        return true;
    }

    function _cancelPair(uint256 _pair) private returns(bool) {
        if(pairsInfo[_pair].settled){
            return false;
        }
        address betterA = betsInfo[pairsInfo[_pair].betIdA].better;
        address betterB = betsInfo[pairsInfo[_pair].betIdB].better;
        bal[betterA] += pairsInfo[_pair].amountA;
        bal[betterB] += pairsInfo[_pair].amountB;
        pairsInfo[_pair].settled = true;
        return true;
    }
    
    function _settlePair(uint256 _pair) private nonReentrant returns(bool) {
        if(pairsInfo[_pair].settled){
            return false;
        }
        address winner;
        address affiliate;
        uint256 winAmount;
        uint256 vigAmount;
        if(status == 1){
            winner = betsInfo[pairsInfo[_pair].betIdA].better;
            winAmount = pairsInfo[_pair].amountA + (pairsInfo[_pair].amountB * (100 - a.vig) / 100);
            vigAmount = pairsInfo[_pair].amountB * a.vig / 100;
            affiliate = betsInfo[pairsInfo[_pair].betIdA].affiliate;
        }
        else if(status == 2){
            winner = betsInfo[pairsInfo[_pair].betIdB].better;
            winAmount = pairsInfo[_pair].amountB + (pairsInfo[_pair].amountA * (100 - a.vig) / 100);
            vigAmount = pairsInfo[_pair].amountA * a.vig / 100;
            affiliate = betsInfo[pairsInfo[_pair].betIdB].affiliate;
        }
        else{
            return false;
        }
        bal[winner] += winAmount;
        bal[a.holdAddr] += vigAmount * a.hVig / 100;
        bal[a.ecoAddr] += vigAmount * a.eVig / 100;
        bal[affiliate] += vigAmount * a.aVig / 100;
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
    returns(uint256)
    {
        uint256 betId;
        uint i = 0;
        while(i >= 0){
            betId = pairs.length + 1 + i;
            if(betsInfo[betId].stake == 0){
                break;
            }
            i++;
        }
        if(_affiliate == address(0)){
            _affiliate = a.ecoAddr;
        }
        betsInfo[betId] = Struct.MarketBet(_better, _affiliate, _stake, _matched, _odds, _side);
        bets.push(betId);
        userBets[_better].push(betId);
        return betId;
    }

    function _createPair(
        uint256 _betIdA,
        uint256 _betIdB,
        uint256 _amountA,
        uint256 _amountB
    ) 
    private
    returns(uint256)
    {
        uint256 pairId;
        uint i = 0;
        while(i >= 0){
            pairId = pairs.length + 1 + i;
            if(pairsInfo[pairId].amountA == 0){
                break;
            }
            i++;
        }
        pairsInfo[pairId] = Struct.MarketPair(_betIdA, _betIdB, _amountA, _amountB, false);
        pairs.push(pairId);

        emit PairCreated(_betIdA, _betIdB, _amountA, _amountB);
        return pairId;
    }
    
}