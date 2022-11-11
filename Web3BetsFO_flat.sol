// SPDX-License-Identifier: MIT

// File: contracts/interface/IEventFactory.sol



pragma solidity ^0.8.4;

interface IEventFactory {
    event EventCreated(address eventAddress, address eventOwner);

    function getFactory() external view returns(address);

    function getEvents() external view returns(address[] memory);

    function getUserEvents(address _user) external view returns(address[] memory);

    function createEvent() external returns(address);

}
// File: contracts/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/interface/IWeb3BetsFO.sol



pragma solidity ^0.8.4;

interface IWeb3BetsFO{
    event FactoryCreated(address factoryAddress);

    function holdAddr() external view returns(address);

    function ecoAddr() external view returns(address);

    function scAddr() external view returns(address);

    function hVig() external view returns(uint256);

    function eVig() external view returns(uint256);

    function aVig() external view returns(uint256);

    function vig() external view returns(uint256);

    function minStake() external view returns(uint256);

    function isBlack(address _addr) external view returns(bool);

    function isEventAdmin(address _addr) external view returns(bool);
}
// File: contracts/interface/IEvent.sol



pragma solidity ^0.8.4;

interface IEvent {
    struct Winner {
        address market;
        uint winningSide;
    }

    event MarketCreated(address eventAddress, address marketAddress);

    function status() external view returns(uint256);

    function owner() external view returns(address);

    function getMarkets() external view returns(address[] memory);

    function start() external;

    function end() external;

    function cancel() external;

    function createMarket() external returns(address);

    function setMarketsWinners(Winner[] calldata _winners) external;

    function settleMarkets(Winner[] calldata _winners) external;

}
// File: contracts/library/Struct.sol



pragma solidity ^0.8.4;

library Struct {

    struct App {
        address holdAddr;
        address ecoAddr;
        uint256 minStake;
        uint256 vig;
        uint256 aVig;
        uint256 eVig;
        uint256 hVig;
    }

    struct MarketBet {
        address better;
        address affiliate;
        uint256 stake;
        uint256 matched;
        uint256 odds;
        uint256 side;
    }
    
    struct MarketPair {
        uint256 betIdA;
        uint256 betIdB;
        uint256 amountA;
        uint256 amountB;
        bool settled;
    }
}
// File: contracts/interface/IMarket.sol



pragma solidity ^0.8.4;


interface IMarket{
    event Withdraw(
        address beneficiary,
        uint256 value
    );

    event BetCreated(
        address better,
        address marketAddr,
        uint256 id,
        uint256 stake,
        uint256 odds,
        uint256 side
    );

    event PairCreated(
        uint256 betIdA,
        uint256 betIdB,
        uint256 amountA,
        uint256 amountB
    );

    function status() external view returns (uint256);

    function getBalance(address _user) external view returns(uint256);

    function getUserBets(address _user) external view returns(uint256[] memory);

    function getBets() external view returns(uint256[] memory);

    function getBet(uint256 _bet) external view returns(Struct.MarketBet memory);

    function getBetPairs(uint256 _bet) external view returns(uint256[] memory);

    function getPairs() external view returns(uint256[] memory);

    function getPair(uint256 _pair) external view returns(Struct.MarketPair memory);

    function withdraw(address _address) external returns(bool);

    function withdrawPending(uint256 _bet) external;

    function cancelBet(uint256 _bet) external;

    function settleBet(uint256 _bet) external;

    /*
    @dev 1: side A is winner, 2: side B is winer
    */
    function setWinningSide(uint256 _winningSide) external returns(bool);

    /*
    @dev set winning side and settle all markets
    @dev 1: side A is winner, 2: side B is winer
    */
    function settle(uint256 _winningSide) external returns(bool);

    function cancel() external returns(bool);

    function cancelPlusPairs() external returns(bool);

    function stopNewBet() external returns(bool);

    function addBet(
        address _affiliate,
        uint256 _stake,
        uint256 _odds,
        uint256 _side,
        bool instant
    ) external;

}
// File: contracts/Market.sol



pragma solidity ^0.8.4;






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
// File: contracts/Event.sol



pragma solidity ^0.8.4;


contract Event is IEvent {
    address immutable private web3bets;
    address immutable public override owner;
    uint256 public override status;
    address[] private markets;

    modifier onlyOwner() {
        require(owner == msg.sender, "E1");
        _;
    }

    constructor(address owner_, address web3bets_)
    {
        owner = owner_;
        web3bets = web3bets_;
    }

    function getMarkets() external view override returns(address[] memory)
    {
        return markets;
    }

    function start() external override onlyOwner {
        require(status == 0, "E2");
        status = 1; // event live
        uint marketsLength = markets.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(markets[i]);
            market.stopNewBet();
        }
    }

    function end() external override onlyOwner {
        require(status != 3 && status != 2, "E3");
        uint marketsLength = markets.length;
        uint notSet;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(markets[i]);
            uint s = market.status();
            if(s == 0 || s == 4){
                notSet = 1;
                break;
            }
        }
        if(notSet != 1){
            status = 2; // event ended
        }
    }

    function cancel() external override onlyOwner {
        require(status != 3 && status != 2, "E4");
        status = 3; // event canceled
        uint marketsLength = markets.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(markets[i]);
            market.cancel();
        }
    }

    function createMarket() external override onlyOwner returns(address) {
        require(status == 0 || status == 1, "E5");
        Market market = new Market(web3bets);
        address marketAddress = address(market);
        markets.push(marketAddress);

        emit MarketCreated(address(this), marketAddress);
        return marketAddress;
    }

    function setMarketsWinners(Winner[] calldata _winners) external override onlyOwner {
        require(status == 0 || status == 1, "E6");
        uint marketsLength = _winners.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(_winners[i].market);
            market.setWinningSide(_winners[i].winningSide);
        }
    }

    function settleMarkets(Winner[] calldata _winners) external override onlyOwner {
        require(status == 0 || status == 1, "E7");
        uint marketsLength = _winners.length;
        for(uint i = 0; i < marketsLength; i++){
            IMarket market = IMarket(_winners[i].market);

            market.settle(_winners[i].winningSide);
        }
    }

}
// File: contracts/EventFactory.sol



pragma solidity ^0.8.4;



contract EventFactory is IEventFactory {
    IWeb3BetsFO immutable private app;
    address[] private events;
    mapping(address => address[]) private userEvents;

    constructor(){
        app = IWeb3BetsFO(msg.sender);
    }

    function getFactory() external view override returns(address)
    {
        return address(app);
    }

    function getEvents() external view override returns(address[] memory)
    {
        return events;
    }

    function getUserEvents(address _user) external view override returns(address[] memory) {
        return userEvents[_user];
    }

    function createEvent() external override returns(address)
    {
        require(app.isEventAdmin(msg.sender), "F2");
        require(!app.isBlack(msg.sender), "F3");
        Event e = new Event(msg.sender, address(app));
        address eventAddress = address(e);
        events.push(eventAddress);
        userEvents[msg.sender].push(eventAddress);

        emit EventCreated(eventAddress, msg.sender);
        return eventAddress;
    }
}
// File: contracts/Web3BetsFO.sol



pragma solidity ^0.8.4;


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