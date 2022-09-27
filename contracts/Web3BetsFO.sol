// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IWeb3BetsFO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Web3BetsFO is IWeb3BetsFO, AccessControlEnumerable {
    using SafeERC20 for IERC20;
    
    address public override eventFactory;
    address public override marketFactory;
    address public override betFactory;
    address public override ecosystemAddress;
    address public override holdersAddress;
    address public override stableCoin;
    uint256 public override holdersVig = 50;
    uint256 public override ecosystemVig = 50;
    uint256 public override vigPercentage = 10;
    IERC20 private _stableCoinWrapper = IERC20(stableCoin);

    bytes32 public constant SYSTEM_ADMIN = keccak256("SYSTEM_ADMIN");
    bytes32 public constant EVENT_ADMIN = keccak256("EVENT_ADMIN");
    bytes32 public constant BLACKLIST = keccak256("BLACKLIST");

    modifier onlySystemAdmin() {
        require(
            hasRole(SYSTEM_ADMIN, msg.sender),
            "You have no privilege to run this function"
        );
        _;
    }

    constructor() {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SYSTEM_ADMIN, msg.sender);
        _setupRole(EVENT_ADMIN, msg.sender);
        _setRoleAdmin(EVENT_ADMIN, SYSTEM_ADMIN);
        _setupRole(BLACKLIST, address(0));
        _setRoleAdmin(BLACKLIST, SYSTEM_ADMIN);
    }

    function setEventFactory(address _factory) public onlySystemAdmin {
        eventFactory = _factory;
    }

    function setMarketFactory(address _factory) public onlySystemAdmin {
        marketFactory = _factory;
    }

    function setBetFactory(address _factory) public onlySystemAdmin {
        betFactory = _factory;
    }

    function setStableCoin(address holder) public onlySystemAdmin {
        holdersAddress = holder;
    }
    
    function setHoldersAddress(address holder) public onlySystemAdmin {
        holdersAddress = holder;
    }

    function setEcosystemAddress(address holder) public onlySystemAdmin {
        ecosystemAddress = holder;
    }

    function setVigPercentage(uint256 _percentage) public onlySystemAdmin {
        require(
            _percentage < 10,
            "Vig percentage must be expressed in 0 to 10 percentage. Example: 6"
        );
        vigPercentage = _percentage;
    }

    function setVigPercentageShares(
        uint256 hVig,
        uint256 eVig
    ) public onlySystemAdmin {
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

    function shareBetEarnings(uint256 _vigAmount) external override {
        require(_vigAmount > 0, "bet earnings must be greater than 0");
        uint256 holdersShare = (_vigAmount * holdersVig )/ 100;
        require(holdersShare > 0, "holders' share must be greater than 0");
        uint256 ecosystemShare = (_vigAmount * ecosystemVig) / 100;
        require(ecosystemShare > 0, "ecosystem share must be greater than 0");

        _stableCoinWrapper.safeTransfer(ecosystemAddress, ecosystemShare);

        _stableCoinWrapper.safeTransfer(holdersAddress, holdersShare);
    }

    function isSystemAdmin(address _account) external view override returns (bool) {
        return hasRole(SYSTEM_ADMIN, _account);
    }

    function isEventAdmin(address _account) external view override returns (bool) {
        return hasRole(EVENT_ADMIN, _account);
    }

    function isBlack(address _account) external view override returns (bool) {
        return hasRole(BLACKLIST, _account);
    }

}