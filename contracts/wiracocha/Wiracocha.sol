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
import "../info/IPachacuyInfo.sol";
import "../token/IPachaCuy.sol";

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

    // Pachacuy Information
    IPachacuyInfo pachacuyInfo;

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

    /**
     * @notice Event emitted when a exchange from sami points to PCUY tokens happens
     * @param exchanger: wallet address of the person making the exchange
     * @param pachaOwner: wallet addres of the pacha owner
     * @param pachaUuid: uuid od the pacha when it was minted
     * @param amountPcuy: amount of PCUY tokens as a result of the exchange
     * @param totalPcuyBalance: total amount of PCUY tokens after the exchange
     * @param samiPoints: amount sami points to be exchange gor PCUY tokens
     * @param ratePcuyToSami: exchange rate between PCUY to sami points
     */
    event WiracochaExchange(
        address exchanger,
        address pachaOwner,
        uint256 pachaUuid,
        uint256 amountPcuy,
        uint256 totalPcuyBalance,
        uint256 samiPoints,
        uint256 ratePcuyToSami
    );

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

    /**
     * @param _exchanger: Wallet address of the user who's exchanging Sami Points to PCUYs
     * @param _pachaOwner: Wallet address of the pacha owner
     * @param _pachaUuid: Uuid of the pacha when it was minted
     * @param _samiPoints: Amount of Sami Points to exchange
     */
    function exchangeSamiToPcuy(
        address _exchanger,
        address _pachaOwner,
        uint256 _pachaUuid,
        uint256 _samiPoints
    ) external onlyRole(GAME_MANAGER) {
        uint256 _amountPcuy = pachacuyInfo.convertSamiToPcuy(_samiPoints);

        IPurchaseAssetController(pachacuyInfo.purchaseACAddress())
            .transferPcuyFromPoolRewardToUser(_exchanger, _amountPcuy);
        ownerToWiracocha[_pachaOwner][_pachaUuid]
            .amountPcuyExchanged += _amountPcuy;

        emit WiracochaExchange(
            _exchanger,
            _pachaOwner,
            _pachaUuid,
            _amountPcuy,
            IPachaCuy(pachacuyInfo.pachaCuyTokenAddress()).balanceOf(
                _exchanger
            ),
            _samiPoints,
            pachacuyInfo.exchangeRatePcuyToSami()
        );
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

    function setPachacuyInfoAddress(address _infoAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachacuyInfo = IPachacuyInfo(_infoAddress);
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
