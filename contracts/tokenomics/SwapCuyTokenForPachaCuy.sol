// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract SwapCuyTokenForPachaCuy is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // tokens
    IERC20Upgradeable pachaCuyToken;
    IERC20Upgradeable cuyToken;

    // rates
    uint256 public exchangeRate;

    // wallet
    address public swapWallet;

    // events
    event SwapCuyTokenForPachaCuyE(
        address swapper,
        uint256 _amountCuyToken,
        uint256 _amountPachaCuy,
        uint256 _exchangeRate
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _cuyToken,
        address _swapWallet,
        uint256 _exchangeRate
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();

        cuyToken = IERC20Upgradeable(_cuyToken);
        swapWallet = _swapWallet;
        exchangeRate = _exchangeRate;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    function swapCuyTokenForPachaCuy(uint256 _amountCuyToken)
        public
        whenNotPaused
    {
        // user gives CuyToken allowance to Smart Contract

        // checks whether swapper has enough CuyToken
        require(
            cuyToken.balanceOf(_msgSender()) >= _amountCuyToken,
            "Swap CT for PC: caller does not have enough CuyToken."
        );

        // checks whether Smart Contract has allowance from user
        require(
            cuyToken.allowance(_msgSender(), address(this)) >= _amountCuyToken,
            "Swap CT for PC: caller needs to give allowance to Smart Contract."
        );

        // calculates exchange amount of Pacha Cuy tokens
        uint256 _amountPachaCuyTokens = getAmountPachaCuyFromCuyToken(
            _amountCuyToken
        );

        // checks if Smart Contract has enough Pacha Cuy Tokens
        require(
            pachaCuyToken.balanceOf(address(this)) >= _amountPachaCuyTokens,
            "Swap CT for PC: Smart Contract does not have enough Pacha Cuy tokens to swap."
        );

        // SC transfers cuytokens from caller to swap wallet
        cuyToken.safeTransferFrom(_msgSender(), swapWallet, _amountCuyToken);

        // transfers Pacha Cuy Tokens to swapper
        pachaCuyToken.safeTransfer(_msgSender(), _amountPachaCuyTokens);

        emit SwapCuyTokenForPachaCuyE(
            _msgSender(),
            _amountCuyToken,
            _amountPachaCuyTokens,
            exchangeRate
        );
    }

    function getAmountPachaCuyFromCuyToken(uint256 _amountCuyToken)
        public
        view
        returns (uint256)
    {
        require(
            exchangeRate != 0,
            "Private Sale: Exchange rate needs to be set."
        );

        return _amountCuyToken.mul(1000).div(exchangeRate).div(10);
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
