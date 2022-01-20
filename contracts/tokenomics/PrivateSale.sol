// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract PrivateSale is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // tokens
    IERC20Upgradeable pachaCuyToken;
    IERC20Upgradeable busdToken;

    // limits
    uint256 public maxPrivateSaleOne;
    uint256 public soldPrivateSaleOne;
    uint256 public maxPrivateSaleTwo;
    uint256 public soldPrivateSaleTwo;

    // private sale state
    bool public privateSaleOneState;
    bool public privateSaleTwoState;

    // rates
    uint256 public exchangeRatePrivateSaleOne;
    uint256 public exchangeRatePrivateSaleTwo;
    uint256 public currentExchangeRatePrivateSale;

    // wallet
    address public walletPrivateSale;

    // events
    event PachaCuyPurchased(
        address _purchaser,
        uint256 _amountBusd,
        uint256 _amountPachaCuy,
        uint256 _exchangeRate
    );
    event ExchangeRateChange(
        uint256 _prevExchangeRate,
        uint256 _nextExchangeRate
    );

    modifier isActivePrivateSaleOne() {
        require(
            privateSaleOneState,
            "Private Sale: Private Sale One is not active"
        );
        _;
    }

    modifier isActivePrivateSaleTwo() {
        require(
            privateSaleTwoState,
            "Private Sale: Private Sale Two is not active"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint256 _maxPrivateSaleOne,
        uint256 _maxPrivateSaleTwo,
        address _busdToken,
        address _walletPrivateSale,
        uint256 _exchangeRatePrivateSaleOne,
        uint256 _exchangeRatePrivateSaleTwo
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();

        // limits
        maxPrivateSaleOne = _maxPrivateSaleOne;
        maxPrivateSaleTwo = _maxPrivateSaleTwo;

        // token
        busdToken = IERC20Upgradeable(_busdToken);
        walletPrivateSale = _walletPrivateSale;

        // rates
        exchangeRatePrivateSaleOne = _exchangeRatePrivateSaleOne;
        exchangeRatePrivateSaleTwo = _exchangeRatePrivateSaleTwo;

        // roles
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    function purchaseTokensWithBusdPrivateSaleOne(uint256 _amountBusd)
        public
        isActivePrivateSaleOne
        whenNotPaused
    {
        uint256 _amountPachaCuyTokens = exchangeBusdToPachaCuy(_amountBusd);

        require(
            _amountPachaCuyTokens + soldPrivateSaleOne <= maxPrivateSaleOne,
            "Private Sale: maximum limit of Pacha Cuy Tokens reached."
        );

        require(
            pachaCuyToken.balanceOf(address(this)) >= _amountPachaCuyTokens,
            "Private Sale: Contract does not have enough tokens to sell."
        );

        soldPrivateSaleOne += _amountPachaCuyTokens;

        _purchaseTokensWithBusd(_amountBusd);
    }

    function purchaseTokensWithBusdPrivateSaleTwo(uint256 _amountBusd)
        public
        isActivePrivateSaleTwo
        whenNotPaused
    {
        uint256 _amountPachaCuyTokens = exchangeBusdToPachaCuy(_amountBusd);

        require(
            _amountPachaCuyTokens + soldPrivateSaleTwo <= maxPrivateSaleTwo,
            "Private Sale: maximum limit of Pacha Cuy Tokens reached."
        );

        require(
            pachaCuyToken.balanceOf(address(this)) >= _amountPachaCuyTokens,
            "Private Sale: Contract does not have enough tokens to sell."
        );

        soldPrivateSaleTwo += _amountPachaCuyTokens;

        _purchaseTokensWithBusd(_amountBusd);
    }

    function _purchaseTokensWithBusd(uint256 _amountBusd)
        internal
        returns (uint256)
    {
        // user gives allowance to sc

        // checks whether sc has allowance from user
        require(
            busdToken.allowance(_msgSender(), address(this)) >= _amountBusd,
            "Private Sale 1: purchaser needs to give allowance to Smart Contract"
        );

        // SC transfers busd from purchaser to wallet private sale
        busdToken.safeTransferFrom(
            _msgSender(),
            walletPrivateSale,
            _amountBusd
        );

        // calculates exchange amount of Pacha Cuy tokens
        uint256 _amountPachaCuyTokens = exchangeBusdToPachaCuy(_amountBusd);

        // transfers Pacha Cuy tokens to purchaser
        pachaCuyToken.safeTransfer(_msgSender(), _amountPachaCuyTokens);

        emit PachaCuyPurchased(
            _msgSender(),
            _amountBusd,
            _amountPachaCuyTokens,
            currentExchangeRatePrivateSale
        );

        return _amountPachaCuyTokens;
    }

    function exchangeBusdToPachaCuy(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        require(
            currentExchangeRatePrivateSale != 0,
            "Private Sale: Exchange rate needs to be set."
        );

        return _amount.mul(currentExchangeRatePrivateSale).div(1e18);
    }

    function setExchangeRatePrivateSale(uint256 _rate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _rate == exchangeRatePrivateSaleOne ||
                _rate == exchangeRatePrivateSaleTwo,
            "Private sale: amount does not match a defined rate."
        );

        emit ExchangeRateChange(currentExchangeRatePrivateSale, _rate);

        currentExchangeRatePrivateSale = _rate;
    }

    function setStatePrivateSaleOne(bool _state)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        privateSaleOneState = _state;
    }

    function setStatePrivateSaleTwo(bool _state)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        privateSaleTwoState = _state;
    }

    function setPachaCuyAddress(address _pachaCuyToken)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken = IERC20Upgradeable(_pachaCuyToken);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
