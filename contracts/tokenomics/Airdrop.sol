// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract Airdrop is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    // Managing contracts
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BACKEND_ADMIN = keccak256("BACKEND_ADMIN");

    // airdrop
    mapping(address => bool) isAccountInAirdrop;
    mapping(address => bool) hasAccountReceivedAirdrop;
    address[] airdropAccountList;
    uint256 public maxAmountAirdropToken;
    event AirdropDelivered(address _account, uint256 _amount);

    // pachacuy token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable pachaCuyToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _backenAddress, address _pachaCuyAddress)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init();

        pachaCuyToken = ERC20Upgradeable(_pachaCuyAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(BACKEND_ADMIN, _backenAddress);
    }

    /**
     * @notice Returns the amount of tokens left to be delivered as airdrop
     * @return amount of pachacuy tokens left as airdrop
     */
    function amountOfTokensRemainingForAirdrop() public view returns (uint256) {
        return pachaCuyToken.balanceOf(address(this));
    }

    /**
     * @notice Sets the maximun amount of tokens this smart contract will hold as airdrop tokens
     * @param _maxAmountAirdropToken: maximun amount of tokens owned by the smart contract
     */
    function setMaxAmoutAirdropToken(uint256 _maxAmountAirdropToken)
        public
        onlyRole(BACKEND_ADMIN)
        whenNotPaused
    {
        maxAmountAirdropToken = _maxAmountAirdropToken;
    }

    mapping(address => uint256) airdropReceived;

    /**
     * @notice Sends airdrop tokens in batches.
     * @param _addresses: list of accounts to received airdrop tokens
     */
    function sendAirdropBatch(
        address[] memory _addresses,
        uint256[] memory _amounts
    ) public onlyRole(BACKEND_ADMIN) whenNotPaused {
        uint256 _amountToAirdrop;
        for (uint256 iy = 0; iy < _amounts.length; iy++) {
            _amountToAirdrop += _amounts[iy];
        }
        require(
            pachaCuyToken.balanceOf(address(this)) >= _amountToAirdrop,
            "Airdrop: Not enough balance for airdrop."
        );

        for (uint256 ix = 0; ix < _addresses.length; ix++) {
            address _account = _addresses[ix];
            uint256 _amount = _amounts[ix];
            pachaCuyToken.safeTransfer(_account, _amount);
            // guardar cuenta y cantidad de airdrops recibidos
            airdropReceived[_account] += _amount; // mapping
            emit AirdropDelivered(_account, _amount);
        }
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

// airdrop puede hacer burn?
// que pasa con los que no reclaman su airdrop?
// hay monto para realizar el airdrop o es de un solo token?
