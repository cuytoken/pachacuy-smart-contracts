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
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
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

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

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
    // Wiracocha UUID  -> Struct of Wiracocha Info
    mapping(uint256 => WiracochaInfo) uuidToWiracochaInfo;

    // Wiracocha uuid => array index
    mapping(uint256 => uint256) internal _wiracochaIx;
    // List of Uuid Wiracochas
    uint256[] listUuidWiracocha;

    mapping(address => bool) internal _ownerHasWiracocha; // DELETE

    mapping(address => mapping(uint256 => bool))
        internal _ownerHasWiracochaAtPacha;

    /**
     * @notice Event emitted when a exchange from sami points to PCUY tokens happens
     * @param exchanger: wallet address of the person making the exchange
     * @param pachaOwner: wallet addres of the pacha owner
     * @param pachaUuid: uuid od the pacha when it was minted
     * @param amountPcuy: amount of PCUY tokens as a result of the exchange
     * @param totalPcuyBalance: total amount of PCUY tokens after the exchange
     * @param samiPoints: amount sami points to be exchange gor PCUY tokens
     * @param ratePcuyToSami: exchange rate between PCUY to sami points
     * @param idFromFront: An ID coming from front to keep track of the exchange at Wiracocha
     */
    event WiracochaExchange(
        address exchanger,
        address pachaOwner,
        uint256 pachaUuid,
        uint256 amountPcuy,
        uint256 totalPcuyBalance,
        uint256 samiPoints,
        uint256 ratePcuyToSami,
        uint256 idFromFront
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
            !_ownerHasWiracochaAtPacha[_account][_pachaUuid],
            "Tatacuy: Already exists one for this pacha"
        );

        _ownerHasWiracochaAtPacha[_account][_pachaUuid] = true;

        uuidToWiracochaInfo[_wiracochaUuid] = WiracochaInfo({
            owner: _account,
            wiracochaUuid: _wiracochaUuid,
            pachaUuid: _pachaUuid,
            creationDate: block.timestamp,
            amountPcuyExchanged: 0,
            hasWiracocha: true
        });

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _wiracochaIx[_wiracochaUuid] = current;
        listUuidWiracocha.push(_wiracochaUuid);
    }

    /**
     * @param _exchanger: Wallet address of the user who's exchanging Sami Points to PCUYs
     * @param _samiPoints: Amount of Sami Points to exchange
     * @param _idFromFront: An ID coming from front to keep track of the exchange at Wiracocha
     */
    function exchangeSamiToPcuy(
        address _exchanger,
        uint256 _samiPoints,
        uint256 _idFromFront,
        uint256 _wiracochaUuid
    ) external onlyRole(GAME_MANAGER) {
        uint256 _amountPcuy = pachacuyInfo.convertSamiToPcuy(_samiPoints);

        IPurchaseAssetController(pachacuyInfo.purchaseACAddress())
            .transferPcuyFromPoolRewardToUser(_exchanger, _amountPcuy);
        uuidToWiracochaInfo[_wiracochaUuid].amountPcuyExchanged += _amountPcuy;

        emit WiracochaExchange(
            _exchanger,
            uuidToWiracochaInfo[_wiracochaUuid].owner,
            uuidToWiracochaInfo[_wiracochaUuid].pachaUuid,
            _amountPcuy,
            IPachaCuy(pachacuyInfo.pachaCuyTokenAddress()).balanceOf(
                _exchanger
            ),
            _samiPoints,
            pachacuyInfo.exchangeRatePcuyToSami(),
            _idFromFront
        );
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    /**
     * @dev Retrives information about a Wiracocha
     * @param _wiracochaUuid: Uuid of the Wiracocha when it was minted
     * @return Gives back an object with the structure of 'WiracochaInfo'
     */
    function getWiracochaWithUuid(uint256 _wiracochaUuid)
        external
        view
        returns (WiracochaInfo memory)
    {
        return uuidToWiracochaInfo[_wiracochaUuid];
    }

    function getListOfWiracochas()
        external
        view
        returns (WiracochaInfo[] memory listOfWiracochas)
    {
        listOfWiracochas = new WiracochaInfo[](listUuidWiracocha.length);
        for (uint256 ix = 0; ix < listUuidWiracocha.length; ix++) {
            listOfWiracochas[ix] = uuidToWiracochaInfo[listUuidWiracocha[ix]];
        }
    }

    function setPachacuyInfoAddress(address _infoAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachacuyInfo = IPachacuyInfo(_infoAddress);
    }

    function hasWiracocha(address _account, uint256 _pachaUuid)
        external
        view
        returns (bool)
    {
        return _ownerHasWiracochaAtPacha[_account][_pachaUuid];
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
