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
////                                                     Pacha                                                   ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../vrf/IRandomNumberGenerator.sol";
import "../purchaseAssetController/IPurchaseAssetController.sol";
import "../info/IPachacuyInfo.sol";

/// @custom:security-contact lee@cuytoken.com
contract Pacha is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    // Pachacuy Information
    IPachacuyInfo pachacuyInfo;

    // typeOfDistribution:PachaPass 1 private with not price | 2 public with price
    // Pacha data
    struct PachaInfo {
        bool isPacha;
        bool isPublic;
        uint256 uuid;
        uint256 pachaPassUuid;
        uint256 pachaPassPrice;
        uint256 typeOfDistribution;
        uint256 idForJsonFile;
        uint256 wasPurchased;
        uint256 location;
        address owner;
    }
    // uuid => Pacha Info
    mapping(uint256 => PachaInfo) internal _uuidToPachaInfo;

    // List of uuids that represet a Pacha
    uint256[] internal listUuidsPachas;
    // Pacha uuid => array index
    mapping(uint256 => uint256) internal _pachaIx;

    // Marks as true when a land has been purchased
    mapping(uint256 => bool) internal isLandAlreadyTaken;

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
     * @param _idForJsonFile: Uuid of the pacha when it was minted
     * @param _pachaUuid: Uuid of the Tatacuy when it was minted
     */
    function registerPacha(
        address _account,
        uint256 _idForJsonFile,
        uint256 _pachaUuid
    ) external onlyRole(GAME_MANAGER) {
        // Mark that space of land as purchased
        isLandAlreadyTaken[_idForJsonFile] = true;

        // Map uuid -> Guinea Pig Struct
        _uuidToPachaInfo[_pachaUuid] = PachaInfo({
            isPacha: true,
            isPublic: true,
            pachaPassUuid: 0,
            pachaPassPrice: 0,
            typeOfDistribution: 0,
            uuid: _pachaUuid,
            location: _idForJsonFile,
            idForJsonFile: _idForJsonFile,
            owner: _account,
            wasPurchased: block.timestamp
        });

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _pachaIx[_pachaUuid] = current;
        listUuidsPachas.push(_pachaUuid);
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function isPachaAlreadyTaken(uint256 _location)
        external
        view
        returns (bool)
    {
        return isLandAlreadyTaken[_location];
    }

    function getListOfPachas()
        external
        view
        returns (PachaInfo[] memory listOfPachas)
    {
        listOfPachas = new PachaInfo[](listUuidsPachas.length);
        for (uint256 ix = 0; ix < listUuidsPachas.length; ix++) {
            listOfPachas[ix] = _uuidToPachaInfo[listUuidsPachas[ix]];
        }
    }

    function getPachaWithUuid(uint256 _pachaUuid)
        external
        view
        returns (PachaInfo memory)
    {
        return _uuidToPachaInfo[_pachaUuid];
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
