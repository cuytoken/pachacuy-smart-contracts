// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract PublicSale is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // token
    IERC20Upgradeable pachaCuyToken;
    IERC20Upgradeable busdToken;

    // Public sale state
    bool public publicSaleState;

    modifier isActivePublicSaleOne() {
        require(publicSaleState, "Public Sale: Public Sale is not active");
        _;
    }

    // limits
    uint256 public maxPublicSale;
    uint256 public soldPublicSale;

    // rates
    uint256 public exchangeRatePublicSale;

    // wallet
    address public walletPublicSale;

    // events
    event PachaCuyPurchased(
        address _purchaser,
        uint256 _amountBusd,
        uint256 _amountPachaCuy,
        uint256 _exchangeRate
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint256 _maxPublicSale,
        address _walletPublicSale,
        address _busdToken
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();

        // limit
        maxPublicSale = _maxPublicSale;

        // deposit to
        walletPublicSale = _walletPublicSale;

        // token
        busdToken = IERC20Upgradeable(_busdToken);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    function purchaseTokensWithBusdPrivateSaleOne(uint256 _amountBusd)
        public
        isActivePublicSaleOne
        whenNotPaused
    {
        require(
            _amountBusd <= 3000 * 10**18,
            "Private Sale: maximun amount of purchase surphased."
        );

        uint256 _amountPachaCuyTokens = getAmountPachaCuyFromBusd(_amountBusd);

        require(
            _amountPachaCuyTokens + soldPublicSale <= maxPublicSale,
            "Private Sale: maximum limit of Pacha Cuy Tokens reached."
        );

        require(
            pachaCuyToken.balanceOf(address(this)) >= _amountPachaCuyTokens,
            "Private Sale: Contract does not have enough tokens to sell."
        );

        soldPublicSale += _amountPachaCuyTokens;

        _purchaseTokensWithBusd(_amountBusd);
    }

    function _purchaseTokensWithBusd(uint256 _amountBusd)
        internal
        returns (uint256)
    {
        // user gives Busd allowance to Smart Contract

        // checks whether Smart Contract has allowance from user
        require(
            busdToken.allowance(_msgSender(), address(this)) >= _amountBusd,
            "Private Sale 1: purchaser needs to give allowance to Smart Contract."
        );

        // SC transfers busd from purchaser to wallet private sale
        busdToken.safeTransferFrom(_msgSender(), walletPublicSale, _amountBusd);

        // calculates exchange amount of Pacha Cuy tokens
        uint256 _amountPachaCuyTokens = getAmountPachaCuyFromBusd(_amountBusd);

        // transfers Pacha Cuy tokens to purchaser
        pachaCuyToken.safeTransfer(_msgSender(), _amountPachaCuyTokens);

        emit PachaCuyPurchased(
            _msgSender(),
            _amountBusd,
            _amountPachaCuyTokens,
            exchangeRatePublicSale
        );

        return _amountPachaCuyTokens;
    }

    function getAmountPachaCuyFromBusd(uint256 _amountBusd)
        public
        view
        returns (uint256)
    {
        require(
            exchangeRatePublicSale != 0,
            "Private Sale: Exchange rate needs to be set."
        );

        return _amountBusd.mul(exchangeRatePublicSale);
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
