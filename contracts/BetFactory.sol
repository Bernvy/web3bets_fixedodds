// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./Bet.sol";
import "./interface/IBetFactory.sol";
import "./interface/IEvent.sol";
import "./interface/IMarket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BetFactory is IBetFactory {

    using SafeERC20 for IERC20;

    address private web3betsAddress;

    IWeb3BetsFO private web3bets = IWeb3BetsFO(web3betsAddress);

    address private stableCoin = web3bets.stableCoin();

    IERC20 private _stableCoinWrapper = IERC20(stableCoin);

    function placeBet(address _marketAddress, string memory _marketSide, uint256 _stake, uint8 _odds)
        public override returns(address) 
    {
        bool isBlack = web3bets.isBlack(msg.sender);
        require(!isBlack, "o 0 black");
        _stake = _stake * 10 ** 18;
        _odds = _odds * 10 ** 2;
        IMarket _market = IMarket(_marketAddress);
        IEvent _event = IEvent(_market.eventAddress());
        require(!(_market.hasSetWinningSide() || _market.isCanceled() ) && _event.status() == IEvent.EventStatus.UPCOMING );
        _stableCoinWrapper.safeTransferFrom(msg.sender, _marketAddress, _stake);
        
        Bet _bet = new Bet(msg.sender, _marketAddress, _marketSide, _stake, _odds);
        
        _market.addBet(msg.sender, address(_bet), _stake, _odds, _marketSide);

        emit BetCreated(msg.sender, _marketAddress, _stake, _odds, _marketSide);
        return address(_bet);
    }

}