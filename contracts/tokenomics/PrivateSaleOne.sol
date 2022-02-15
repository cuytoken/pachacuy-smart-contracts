// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract PrivateSaleOne is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    // Upgrades
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // White list
    mapping(address => bool) whiteList;
    bool public whitelistFilterActive;

    // BUSD token
    IERC20Upgradeable busdToken;

    // custodian wallet for busd
    address custodianWallet;

    // rate
    uint256 public exchangeRate;

    // max purchase per wallet
    uint256 public limitPerWallet;

    // total cap: 1.5 millions
    uint256 maxCapTokensToSell;
    uint256 amountPachacuySold;

    // list of customers
    address[] listOfCustomers;

    // events
    event PachaCuyPurchased(
        address _purchaser,
        uint256 _amountBusd,
        uint256 _amountPachaCuy,
        uint256 _exchangeRate
    );

    // Customers data
    struct Customer {
        address _wallet;
        uint256 _amountBusdSpent;
        uint256 _amountPachacuyToDeliver;
        uint256 _exchangeRate;
    }
    mapping(address => Customer) customers;

    // Events
    event ExchangeRateChange(
        uint256 _prevExchangeRate,
        uint256 _nextExchangeRate
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _busdAddress,
        address _custodianWallet,
        uint256 _rate
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();

        busdToken = IERC20Upgradeable(_busdAddress);
        custodianWallet = _custodianWallet;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // setting exchange rate
        setExchangeRatePrivateSale(_rate);

        // setting max cap
        maxCapTokensToSell = 15 * 10**5 * 10**18;
        listOfCustomers = new address[](0);
        limitPerWallet = 500;
    }

    function purchaseTokensWithBusd(uint256 _amountBusd)
        public
        whenNotPaused
        nonReentrant
    {
        // Max 500 BUSD per account
        uint256 _amountBusdSpent = customers[_msgSender()]._amountBusdSpent;
        uint256 _amountPachacuyPrev = customers[_msgSender()]
            ._amountPachacuyToDeliver;

        require(
            whiteList[_msgSender()] || !whitelistFilterActive,
            "Private Sale: Customer is not in Whitelist."
        );

        require(
            _amountBusdSpent.add(_amountBusd) <= limitPerWallet * 10**18,
            "Private Sale: 500 BUSD is the maximun amount of purchase."
        );

        // Verify if customer has BUSDC balance
        require(
            busdToken.balanceOf(_msgSender()) >= _amountBusd,
            "Private Sale: Customer does not have enough balance."
        );

        // Verify id customer has given allowance to Private Sale smart contract
        require(
            busdToken.allowance(_msgSender(), address(this)) >= _amountBusd,
            "Private Sale: Customer didn't give allowance."
        );

        uint256 _amountPachaCuyToPurchase = getAmountPachaCuyFromBusd(
            _amountBusd
        );

        // Verify that there are enough pachacuy tokens to sell
        require(
            maxCapTokensToSell.sub(amountPachacuySold).sub(
                _amountPachaCuyToPurchase
            ) >= 0,
            "Private Sale: not enough Pachacuy to sell."
        );

        // SC transfers BUSD from purchaser to custodian wallet
        busdToken.safeTransferFrom(_msgSender(), custodianWallet, _amountBusd);

        // register operation
        customers[_msgSender()] = Customer(
            _msgSender(),
            _amountBusdSpent.add(_amountBusd),
            _amountPachacuyPrev.add(_amountPachaCuyToPurchase),
            exchangeRate
        );

        // save to customer list
        listOfCustomers.push(_msgSender());

        // updates count
        amountPachacuySold += _amountPachaCuyToPurchase;

        emit PachaCuyPurchased(
            _msgSender(),
            _amountBusd,
            _amountPachaCuyToPurchase,
            exchangeRate
        );
    }

    // Consult Balance of a customer
    function queryBalance(address _account)
        external
        view
        returns (
            address _walletCusomter,
            uint256 _busdSpent,
            uint256 _pachacuyPurchased,
            uint256 _rate
        )
    {
        _walletCusomter = customers[_account]._wallet;
        _busdSpent = customers[_account]._amountBusdSpent;
        _pachacuyPurchased = customers[_account]._amountPachacuyToDeliver;
        _rate = customers[_account]._exchangeRate;
    }

    // fills customers in whitelist
    function addToWhitelistBatch(address[] memory _addresses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        for (uint256 iy = 0; iy < _addresses.length; iy++) {
            whiteList[_addresses[iy]] = true;
        }
    }

    function enableWhitelistFilter()
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        require(
            !whitelistFilterActive,
            "Private Sale: Whitelist filter already active."
        );
        whitelistFilterActive = true;
    }

    function disableWhitelistFilter()
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        require(
            whitelistFilterActive,
            "Private Sale: Whitelist filter already active."
        );
        whitelistFilterActive = false;
    }

    function retrieveListOfCustomers()
        external
        view
        returns (address[] memory)
    {
        return listOfCustomers;
    }

    function amountPachacuyLeftToSell() external view returns (uint256) {
        return maxCapTokensToSell.sub(amountPachacuySold);
    }

    function amountPachacuySoldSoFar() external view returns (uint256) {
        return amountPachacuySold;
    }

    function setAddressBusd(address _busdAddress)
        public
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        busdToken = IERC20Upgradeable(_busdAddress);
    }

    function setExchangeRatePrivateSale(uint256 _rate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit ExchangeRateChange(exchangeRate, _rate);

        exchangeRate = _rate;
    }

    function getAmountPachaCuyFromBusd(uint256 _amountBusd)
        internal
        view
        returns (uint256)
    {
        require(
            exchangeRate != 0,
            "Private Sale: Exchange rate needs to be set."
        );

        return _amountBusd.mul(exchangeRate);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
