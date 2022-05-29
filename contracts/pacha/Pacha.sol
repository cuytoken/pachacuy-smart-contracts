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

    // function setPachaToPublic(uint256 _landUuid) public {
    //     // Verify that land's uuid exists
    //     require(exists(_landUuid), "NFP: land uuid does not exist");

    //     // Verify that is land's owner
    //     require(
    //         _uuidToLandData[_landUuid].owner == _msgSender(),
    //         "NFP: you are not the owner of this land"
    //     );

    //     // Verify that land is private
    //     require(
    //         !_uuidToLandData[_landUuid].isPublic,
    //         "NFP: land must be private"
    //     );

    //     // make the land public
    //     _uuidToLandData[_landUuid].isPublic = true;
    // }

    // /**
    //  * @notice Set a Pacha to private and choose type of distribution (private with not price or public with price)
    //  * @param _landUuid uuid of the land for which the pacha pass will be created
    //  * @param _price cost of pachapass in PCUY. If '_typeOfDistribution' is 1, '_price' must be 0
    //  * @param _typeOfDistribution (1, 2) - private distribution (no price) or public sale of pacha pass
    //  * @param _accounts list of addresses to mint the pachapass. If empty array is passed there is no mint of pacha passes
    //  */
    // function setPachaToPrivateAndDistribution(
    //     uint256 _landUuid,
    //     uint256 _price,
    //     uint256 _typeOfDistribution,
    //     address[] memory _accounts
    // ) public {
    //     // Verify that land's uuid exists
    //     require(exists(_landUuid), "NFP: land uuid does not exist");

    //     // Verify that is land's owner
    //     require(
    //         _uuidToLandData[_landUuid].owner == _msgSender(),
    //         "NFP: you are not the owner of this land"
    //     );

    //     // Verify that distribution is either 0 or 1
    //     require(
    //         _typeOfDistribution == 1 || _typeOfDistribution == 2,
    //         "NFP: distribution is 1 or 2"
    //     );

    //     // Verify that land is public
    //     require(
    //         _uuidToLandData[_landUuid].isPublic,
    //         "NFP: land must be public"
    //     );

    //     // make the land private
    //     _uuidToLandData[_landUuid].isPublic = false;

    //     // set type of distribution for land
    //     _uuidToLandData[_landUuid].typeOfDistribution = _typeOfDistribution;

    //     // Creates a UUID for each mint
    //     uint256 _uuid = _tokenIdCounter.current();
    //     // For a land, set its pacha pass uuid
    //     _uuidToLandData[_landUuid].pachaPassUuid = _uuid;

    //     // if type of distribution of pachapass is private (with no price)
    //     if (_typeOfDistribution == 1) {
    //         require(_price == 0, "Nft. P: price must be 0");
    //     } else if (_typeOfDistribution == 2) {
    //         // if type of distribution of pachapass is public (with price)
    //         require(_price > 0, "Nft. P: price greater than 0");
    //         // For a land, set its pacha pass price
    //         _uuidToLandData[_landUuid].pachaPassPrice = _price;
    //     }

    //     // If there are accounts, mint the pacha pass to each address
    //     if (_accounts.length > 0) {
    //         for (uint256 i = 0; i < _accounts.length; i++) {
    //             _mintPachaPassNft(
    //                 _accounts[i],
    //                 _landUuid,
    //                 _uuid,
    //                 _typeOfDistribution,
    //                 _price,
    //                 "transferred"
    //             );
    //         }
    //     }

    //     _tokenIdCounter.increment();
    // }

    // function _mintPachaPassNft(
    //     address _account,
    //     uint256 _landUuid,
    //     uint256 _uuidPachaPass,
    //     uint256 _typeOfDistribution,
    //     uint256 _price,
    //     string memory _transferMode
    // ) internal {
    //     _mint(_account, _uuidPachaPass, 1, "");

    //     // Map owner -> uuid[]
    //     _ownerToUuids[_account].push(_uuidPachaPass);
    //     _setApprovalForAll(_account, address(this), true);

    //     // Map uuid -> Pacha Pass Struct
    //     _uuidToPachaPassData[_uuidPachaPass] = PachaPassdata({
    //         isPachaPass: true,
    //         pachaUuid: _landUuid,
    //         typeOfDistribution: _typeOfDistribution,
    //         uuid: _uuidPachaPass,
    //         cost: _price,
    //         transferMode: _transferMode
    //     });
    // }

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
