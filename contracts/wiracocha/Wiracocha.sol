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
////                                                  Wiracocha                                                  ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../purchaseAssetController/IPurchaseAssetController.sol";

/// @custom:security-contact lee@cuytoken.com
contract Wiracocha is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    IPurchaseAssetController public purchaseAssetController;

    /**
     * @dev Details the information of a Tatacuy. Additional properties attached for its campaign
     * @param owner: Wallet address of the current owner of Wiracocha
     * @param wiracochaUuid: Uuid of the Tatacuy when it was minted
     * @param pachaUuid: Uuid of the pacha where this Tatacuy is located
     * @param creationDate: Timestamp of the Tatacuy when it was minted
     * @param hasWiracocha: Whether a Wiracocha exists or not
     */
    struct WiracochaInfo {
        address owner;
        uint256 wiracochaUuid;
        uint256 pachaUuid;
        uint256 creationDate;
        uint256 amountPcuyExchanged;
        bool hasWiracocha;
    }
    // Owner Tatacuy -> Pacha UUID -> Wiracocha UUID  -> Struct of Wiracocha Info
    mapping(address => mapping(uint256 => WiracochaInfo)) ownerToWiracocha;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
    }

    /**
     * @dev Trigger when it is minted
     * @param _account: Wallet address of the current owner of the Pacha
     * @param _pachaUuid: Uuid of the pacha when it was minted
     * @param _wiracochaUuid: Uuid of the Wiracocha when it was minted
     */
    function registerWiracocha(
        address _account,
        uint256 _pachaUuid,
        uint256 _wiracochaUuid,
        bytes memory
    ) external onlyRole(GAME_MANAGER) {
        require(
            !ownerToWiracocha[_account][_pachaUuid].hasWiracocha,
            "Tatacuy: Already exists one for this pacha"
        );

        ownerToWiracocha[_account][_pachaUuid] = WiracochaInfo({
            owner: _account,
            wiracochaUuid: _wiracochaUuid,
            pachaUuid: _pachaUuid,
            creationDate: block.timestamp,
            amountPcuyExchanged: 0,
            hasWiracocha: true
        });
    }

    function exchangeSamiToPcuy(
        address _account,
        uint256 _pachaUuid,
        uint256 _samiPoints,
        uint256 _amountPcuy,
        uint256 _rateSamiPointsToPcuy
    ) external onlyRole(GAME_MANAGER) {
        purchaseAssetController.transferPcuyFromPoolRewardToUser(
            _account,
            _amountPcuy
        );
        ownerToWiracocha[_account][_pachaUuid]
            .amountPcuyExchanged += _amountPcuy;

        // crear evento wiracocha
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    /**
     * @dev Retrives information about a Wiracocha
     * @param _account: Wallet address of the user who owns a Wiracocha (hence a Pacha)
     * @param _pachaUuid: Uuid of the pacha when it was minted
     * @return Gives back an object with the structure of 'WiracochaInfo'
     */
    function getWiracochaInfoForAccount(address _account, uint256 _pachaUuid)
        external
        view
        returns (WiracochaInfo memory)
    {
        return ownerToWiracocha[_account][_pachaUuid];
    }

    function setAddressPurchaseAssetController(address _purchaseAssetController)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        purchaseAssetController = IPurchaseAssetController(
            _purchaseAssetController
        );
    }

    ///////////////////////////////////////////////////////////////
    ////                   STANDARD FUNCTIONS                  ////
    ///////////////////////////////////////////////////////////////

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
