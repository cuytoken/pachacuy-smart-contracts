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
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact lee@pachacuy.com
contract PachaCuyToken is
    ERC777,
    IERC777Sender,
    IERC777Recipient,
    Pausable,
    AccessControl
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

    constructor(
        address _vesting,
        address _publicSale,
        address _gameRewards,
        address _proofOfHold,
        address _pachacuyEvolution,
        address[] memory defaultOperators_
    ) ERC777("Pachacuy", "PCUY", defaultOperators_) {
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
}
