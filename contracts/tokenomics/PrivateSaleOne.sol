// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract MyToken is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Upgrades
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // BUSD token
    IERC20Upgradeable busdToken;

    // custodian wallet for busd
    address custodianWallet;

    // rate
    uint256 public exchangeRate;

    // total cap: 1.5 millions
    uint256 maxCapTokensToSell = 15 * 10**5 * 10**18;
    uint256 amountPachacuySold = 0;

    // list of customers
    address[] listOfCustomers = new address[](0);

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
        __ERC20_init("MyToken", "MTK");
        __Pausable_init();
        __AccessControl_init();

        busdToken = IERC20Upgradeable(_busdAddress);
        custodianWallet = _custodianWallet;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());

        // setting exchange rate
        setExchangeRatePrivateSale(_rate);
    }

    function purchaseTokensWithBusd(uint256 _amountBusd) public whenNotPaused {
        // Max 500 BUSD per account
        uint256 _amountBusdSpent = customers[_msgSender()]._amountBusdSpent;
        require(
            _amountBusdSpent <= 500 * 10**18,
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
            "Private Sale Customer didn't give allowance."
        );

        uint256 _amountPachaCuyToPurchase = getAmountPachaCuyFromBusd(
            _amountBusd
        );

        // Verify that there are enough pachacuy tokens to sell
        require(
            maxCapTokensToSell.sub(amountPachacuySold).sub(
                _amountPachaCuyToPurchase
            ) >= 0,
            "Private Sale: not enough pachacuy to sell."
        );

        // SC transfers BUSD from purchaser to custodian wallet
        busdToken.safeTransferFrom(_msgSender(), custodianWallet, _amountBusd);

        // register operation
        customers[_msgSender()] = Customer(
            _msgSender(),
            _amountBusdSpent.add(_amountBusd),
            _amountPachaCuyToPurchase,
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

    function retrieveListOfCustomers()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address[] memory)
    {
        return listOfCustomers;
    }

    function amountPachacuyLeftToSell() external view returns (uint256) {
        return maxCapTokensToSell - amountPachacuySold;
    }

    function setExchangeRatePrivateSale(uint256 _rate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _rate == exchangeRate,
            "Private sale: amount does not match a defined rate."
        );

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

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
