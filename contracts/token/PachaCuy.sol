/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////      ___         ___           ___           ___           ___           ___           ___                  ////
////     /  /\       /  /\         /  /\         /__/\         /  /\         /  /\         /__/\          ___    ////
////    /  /::\     /  /::\       /  /:/         \  \:\       /  /::\       /  /:/         \  \:\        /__/|   ////
////   /  /:/\:\   /  /:/\:\     /  /:/           \__\:\     /  /:/\:\     /  /:/           \  \:\      |  |:|   ////
////  /  /:/~/:/  /  /:/~/::\   /  /:/  ___   ___ /  /::\   /  /:/~/::\   /  /:/  ___   ___  \  \:\     |  |:|   ////
//// /__/:/ /:/  /__/:/ /:/\:\ /__/:/  /  /\ /__/\  /:/\:\ /__/:/ /:/\:\ /__/:/  /  /\ /__/\  \__\:\  __|__|:|   ////
//// \  \:\/:/   \  \:\/:/__\/ \  \:\ /  /:/ \  \:\/:/__\/ \  \:\/:/__\/ \  \:\ /  /:/ \  \:\ /  /:/ /__/::::\   ////
////  \  \::/     \  \::/       \  \:\  /:/   \  \::/       \  \::/       \  \:\  /:/   \  \:\  /:/     ~\~~\:\  ////
////   \  \:\      \  \:\        \  \:\/:/     \  \:\        \  \:\        \  \:\/:/     \  \:\/:/        \  \:\ ////
////    \  \:\      \  \:\        \  \::/       \  \:\        \  \:\        \  \::/       \  \::/          \__\/ ////
////     \__\/       \__\/         \__\/         \__\/         \__\/         \__\/         \__\/                 ////
////                                                                                                             ////
////                                                 LAND OF CUYS                                                ////
////                                                 PachaCuyToken                                               ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777SenderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../info/IPachacuyInfo.sol";

/// @custom:security-contact lee@pachacuy.com
contract PachaCuyToken is
    Initializable,
    ERC777Upgradeable,
    IERC777SenderUpgradeable,
    IERC777RecipientUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event TokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    event TokensSent(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    event HasReceivedPcuy(address account, bool hasReceived, uint256 balance);

    mapping(address => bool) internal test_addressReceived;

    event Balances(uint256 maticBalance, uint256 pcuyBalance);

    IPachacuyInfo pachacuyInfo;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _vesting,
        address _publicSale,
        address _gameRewards,
        address _proofOfHold,
        address _pachacuyEvolution,
        address[] memory defaultOperators_
    ) public initializer {
        __ERC777_init("Pachacuy", "PCUY", defaultOperators_);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());

        // Distribution:         (M)
        // VESTING               36.3
        // PUBLIC SALE           1.7
        // PACHACUY  REWARDS     36
        // PROOF OF HOLD         6
        // PACHACUY EVOLUCION    20
        // -------------------------
        // TOTAL                 100

        //_vesting
        _mint(_vesting, 363 * 1e5 * 1e18, "", "");

        //_publicSale
        _mint(_publicSale, 17 * 1e5 * 1e18, "", "");

        //_gameRewards
        _mint(_gameRewards, 36 * 1e6 * 1e18, "", "");

        //_proofOfHold
        _mint(_proofOfHold, 6 * 1e6 * 1e18, "", "");

        //_pachacuyEvolution
        _mint(_pachacuyEvolution, 20 * 1e6 * 1e18, "", "");
    }

    function test_mint(address _account, uint256 _amount) external {
        require(
            _msgSender() == 0xA2a24EeB8f3FE4c7253b2023111f7d5Ac3C11CAe,
            "PCUY: Not Authorized"
        );

        if (test_addressReceived[_account]) {
            emit HasReceivedPcuy(_account, true, balanceOf(_account));
            return;
        }

        test_addressReceived[_account] = true;
        _mint(_account, _amount, "", "");

        emit HasReceivedPcuy(_account, false, _amount);
    }

    function sendMaticAndTokens(
        address _account,
        uint256 _amount,
        uint256 _id
    ) external payable {
        require(
            _msgSender() == 0xA2a24EeB8f3FE4c7253b2023111f7d5Ac3C11CAe,
            "PCUY: Not Authorized"
        );

        (address wallet, bool included) = pachacuyInfo.isWhiteListed(_id);
        if (included) {
            if (wallet != _account) return;
        }
        pachacuyInfo.updateWhitelist(_account, true, _id);

        uint256 _balAccount = address(_account).balance;
        if (_balAccount < 0.2 ether) {
            (bool sent, ) = _account.call{value: (0.2 ether - _balAccount)}("");
            require(sent, "Error sending matic");
        }
        if (!test_addressReceived[_account]) {
            test_addressReceived[_account] = true;
            _mint(_account, _amount, "", "");
        }
        emit Balances(address(_account).balance, balanceOf(_account));
    }

    function setPachacuyInfoAddress(address _pachacuyInfo)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachacuyInfo = IPachacuyInfo(_pachacuyInfo);
    }

    receive() external payable {}

    function hasReceived(address _account)
        external
        view
        returns (
            address,
            bool,
            uint256
        )
    {
        return (_account, test_addressReceived[_account], balanceOf(_account));
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensReceived(operator, from, to, amount, userData, operatorData);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensSent(operator, from, to, amount, userData, operatorData);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    function revokeOperator(address operator) public virtual override {}

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
