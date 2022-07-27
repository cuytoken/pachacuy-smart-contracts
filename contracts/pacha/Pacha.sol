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
import "../NftProducerPachacuy/INftProducerPachacuy.sol";

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
    CountersUpgradeable.Counter private _tokenIdCounterPacha;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounterPachaPass;

    using StringsUpgradeable for uint256;

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
        uint256 price;
        address[] listPachaPassOwners;
    }
    // uuid => Pacha Info
    mapping(uint256 => PachaInfo) internal _uuidToPachaInfo;

    // List of uuids that represet a Pacha
    uint256[] internal listUuidsPachas;
    // Pacha uuid => array index
    mapping(uint256 => uint256) internal _pachaIx;

    // Marks as true when a land has been purchased
    mapping(uint256 => bool) internal isLandAlreadyTaken;

    // Pacha Pass Data
    /**
     * @param isPachaPass: Indicates whether the pacha pass exists or not
     * @param pachaUuid: Uuid of the Pacha where the pacha pass belongs to
     * @param typeOfDistribution: 1 -> private and no price, 2 -> with price and public sale
     * @param uuid: Uuid of the pacha pass
     * @param price: Price paid to obtain the pachapass
     * @param transferMode: Either "transferred" (Type Dist. 1 - private sale) or "purchased" (Type Dist. 2 - public sale)
     */
    struct PachaPassInfo {
        bool isPachaPass;
        uint256 pachaUuid;
        uint256 typeOfDistribution;
        uint256 uuid;
        uint256 price;
        string transferMode;
        address[] listPachaPassOwners;
    }
    // uuid Pacha Pass => Pacha Pass Info
    mapping(uint256 => PachaPassInfo) internal _uuidToPachaPassInfo;
    // List of uuids that represet a Pacha Pass
    uint256[] internal _listUuidsPachaPasses;

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

    function validateMint(bytes memory _data) external view returns (bool) {
        (, uint256 _location, ) = abi.decode(
            _data,
            (address, uint256, uint256)
        );
        require(!isLandAlreadyTaken[_location], "NFP: location taken");
        return !isLandAlreadyTaken[_location];
    }

    // /**
    //  * @dev Trigger when it is minted
    //  * @param _account: Wallet address of the current owner of the Pacha
    //  * @param _idForJsonFile: Uuid of the pacha when it was minted
    //  * @param _pachaUuid: Uuid of the Pacha when it was minted
    //  */
    function registerNft(bytes memory _data) external {
        (
            address _account,
            uint256 _idForJsonFile,
            uint256 _price,
            uint256 _pachaUuid
        ) = abi.decode(_data, (address, uint256, uint256, uint256));

        // validates location between 1 - 697
        require(
            _idForJsonFile > 0 && _idForJsonFile < 698,
            "Pacha: Out of bounds"
        );

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
            wasPurchased: block.timestamp,
            price: _price,
            listPachaPassOwners: new address[](0)
        });

        uint256 current = _tokenIdCounterPacha.current();
        _tokenIdCounterPacha.increment();

        _pachaIx[_pachaUuid] = current;
        listUuidsPachas.push(_pachaUuid);
    }

    function transfer(
        address _oldOwner,
        address _newOwner,
        uint256 _uuid,
        uint256
    ) external onlyRole(GAME_MANAGER) {
        if (_uuidToPachaInfo[_uuid].isPacha) {
            _uuidToPachaInfo[_uuid].owner = _newOwner;

            // move all uuids within this pacha to the new owner
        } else if (_uuidToPachaPassInfo[_uuid].isPachaPass) {
            // remove old pacha pass owner from pacha pass list
            address[] storage listPP = _uuidToPachaPassInfo[_uuid]
                .listPachaPassOwners;
            uint256 ixForChange = 0;
            for (uint256 ix = 0; ix < listPP.length; ix++) {
                if (listPP[ix] == _oldOwner) {
                    ixForChange = ix;
                    break;
                }
            }
            listPP[ixForChange] = _newOwner;

            // remove old pacha pass owner from pacha list
            uint256 pachaUuid = _uuidToPachaPassInfo[_uuid].pachaUuid;
            address[] storage listP = _uuidToPachaInfo[pachaUuid]
                .listPachaPassOwners;
            listP[ixForChange] = _newOwner;
        }
    }

    /**
     * @notice Converts a private pacha to a public pacha
     * @param _pachaUuid: Uuif of the pacha that will become public (no pacha pass required)
     */
    function setPachaToPublic(uint256 _pachaUuid) public {
        // Verify that land's uuid exists
        PachaInfo storage pacha = _uuidToPachaInfo[_pachaUuid];
        require(pacha.isPacha, "Pacha: non-existant uuid");

        // Verify that is land's owner
        require(pacha.owner == _msgSender(), "Pacha: not the owner");

        // Verify that land is private
        require(!pacha.isPublic, "Pacha: land must be private");

        // make the land public
        pacha.isPublic = true;
    }

    /**
     * @notice Set a Pacha to private and choose type of distribution (private with not price or public with price)
     * @param _pachaUuid uuid of the land for which the pacha pass will be created
     * @param _price price of pachapass in PCUY. If '_typeOfDistribution' is 1, '_price' must be 0
     * @param _typeOfDistribution (1, 2) - private distribution (no price) or public sale of pacha pass
     */
    function setPachaPrivacyAndDistribution(
        uint256 _pachaUuid,
        uint256 _price,
        uint256 _typeOfDistribution
    ) public {
        PachaInfo storage pacha = _uuidToPachaInfo[_pachaUuid];
        // Verify that land's uuid exists
        require(pacha.isPacha, "Pacha: Non-existant uuid");

        // Verify that is land's owner
        require(pacha.owner == _msgSender(), "Pacha: not the owner");

        // Verify that distribution is either 0 or 1
        require(
            _typeOfDistribution == 1 || _typeOfDistribution == 2,
            "Pacha: not 1 neither 2"
        );

        // Verify that land is public
        require(pacha.isPublic, "Pacha: not public");

        // make the land private
        pacha.isPublic = false;

        // set type of distribution for land
        pacha.typeOfDistribution = _typeOfDistribution;

        if (pacha.pachaPassUuid == 0) {
            pacha.pachaPassUuid = INftProducerPachacuy(
                pachacuyInfo.nftProducerAddress()
            ).createPachaPassId();
        }

        // if type of distribution of pachapass is private (with no price)
        if (_typeOfDistribution == 1) {
            require(_price == 0, "Pacha: price must be 0");
        } else if (_typeOfDistribution == 2) {
            // if type of distribution of pachapass is public (with price)
            require(_price > 0, "Pacha: price greater than 0");
            // For a land, set its pacha pass price
            pacha.pachaPassPrice = _price;
        }

        // PACHA PASS
        PachaPassInfo storage pachaPassInfo = _uuidToPachaPassInfo[
            pacha.pachaPassUuid
        ];

        // alreadys set up before and wants to update
        if (pachaPassInfo.isPachaPass) {
            pachaPassInfo.price = _price;
            pachaPassInfo.typeOfDistribution = _typeOfDistribution;
        } else {
            // first time seting up pacha
            _uuidToPachaPassInfo[pacha.pachaPassUuid] = PachaPassInfo({
                isPachaPass: true,
                pachaUuid: _pachaUuid,
                typeOfDistribution: _typeOfDistribution,
                uuid: pacha.pachaPassUuid,
                price: _price,
                transferMode: "",
                listPachaPassOwners: new address[](0)
            });
            _listUuidsPachaPasses.push(pacha.pachaPassUuid);
        }
    }

    function registerPachaPass(
        address _account,
        uint256 _pachaUuid,
        uint256 _pachaPassUuid,
        string memory _transferMode
    ) external onlyRole(GAME_MANAGER) {
        PachaPassInfo storage pachaPassInfo = _uuidToPachaPassInfo[
            _pachaPassUuid
        ];

        pachaPassInfo.transferMode = _transferMode;
        pachaPassInfo.listPachaPassOwners.push(_account);

        _uuidToPachaInfo[_pachaUuid].listPachaPassOwners.push(_account);
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

    function getListOfPachaPasses()
        external
        view
        returns (PachaPassInfo[] memory listOfPachaPasses)
    {
        listOfPachaPasses = new PachaPassInfo[](_listUuidsPachaPasses.length);
        for (uint256 ix = 0; ix < _listUuidsPachaPasses.length; ix++) {
            listOfPachaPasses[ix] = _uuidToPachaPassInfo[
                _listUuidsPachaPasses[ix]
            ];
        }
    }

    function getPachaPassWithUuid(uint256 _pachaPassUuid)
        external
        view
        returns (PachaPassInfo memory)
    {
        return _uuidToPachaPassInfo[_pachaPassUuid];
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

    // _uuid: either _pachaUuid or _pachaPassUuid
    function tokenUri(string memory _prefix, uint256 _uuid)
        external
        view
        returns (string memory)
    {
        if (_uuidToPachaPassInfo[_uuid].isPachaPass) {
            return string(abi.encodePacked(_prefix, "PACHAPASS.json"));
        } else if (_uuidToPachaInfo[_uuid].isPacha) {
            return
                string(
                    abi.encodePacked(
                        _prefix,
                        "PACHA",
                        _uuidToPachaInfo[_uuid].idForJsonFile.toString(),
                        ".json"
                    )
                );
        }
        return "";
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
