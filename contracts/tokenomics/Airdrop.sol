// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract Airdrop is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    // Managing contracts
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // airdrop
    mapping(address => uint256) airdropReceivedPerAccount;
    event AirdropDelivered(address _account, uint256 _amount);

    // pachacuy token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable pachaCuyToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _backenAddress) public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _backenAddress);
    }

    /**
     * @notice Sends airdrop tokens in batches.
     * @param _addresses: list of accounts to received airdrop tokens
     */
    function sendAirdropBatch(
        address[] memory _addresses,
        uint256[] memory _amounts
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        uint256 _amountToAirdrop;
        for (uint256 iy = 0; iy < _amounts.length; iy++) {
            _amountToAirdrop += _amounts[iy];
        }
        require(
            pachaCuyToken.balanceOf(address(this)) >= _amountToAirdrop,
            "Airdrop: Not enough Pacha Cuy balance for airdrop."
        );

        for (uint256 ix = 0; ix < _addresses.length; ix++) {
            address _account = _addresses[ix];
            uint256 _amount = _amounts[ix];
            pachaCuyToken.safeTransfer(_account, _amount);
            airdropReceivedPerAccount[_account] += _amount;
            emit AirdropDelivered(_account, _amount);
        }
    }

    function setPachaCuyAddress(address _pachaCuyToken)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken = IERC20Upgradeable(_pachaCuyToken);
    }

    /**
     * @notice Pauses the contract
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
