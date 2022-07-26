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
////                                                  Guniea Pig                                                 ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../info/IPachacuyInfo.sol";
import "hardhat/console.sol";

/// @custom:security-contact lee@cuytoken.com
contract GuineaPig is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    IPachacuyInfo pachacuyInfo;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    using StringsUpgradeable for uint256;

    // Guinea pig data
    /**
     * @param isGuineaPig: indicates whether the Uuid is a guinea pig or not
     * @param race: indicates the race of the guinea pig: "PERU", "INTI", "ANDINO", "SINTETICO"
     * @param gender: MALE or FEMALE
     * @param speed:
     * @param daysUntilHungry:
     * @param daysUntilDeath:
     * @param samiPoints:
     * @param uuid:
     * @param idForJsonFile:
     * @param feedingDate:
     * @param burningDate:
     * @param wasBorn:
     * @param owner:
     * @param price:
     */
    struct GuineaPigInfo {
        bool isGuineaPig;
        string race;
        string gender;
        uint256 speed;
        uint256 daysUntilHungry;
        uint256 daysUntilDeath;
        uint256 samiPoints;
        uint256 uuid;
        uint256 idForJsonFile;
        uint256 feedingDate;
        uint256 burningDate;
        uint256 wasBorn;
        address owner;
        uint256 price;
    }
    // uuid => GuineaPig
    mapping(uint256 => GuineaPigInfo) internal _uuidToGuineaPigInfo;

    // List of Guinea Pigs
    uint256[] listOfUuidGuineaPigs;
    // guinea pig uuid => array index
    mapping(uint256 => uint256) internal _guineaPigsIx;

    // Guinea Pig races
    string[4] private _races;
    uint256[4] private _speeds;
    uint256[4] private _daysUntilHungry;
    uint256[4] private _daysUntilDeath;
    uint256[4] private _samiPoints;

    // likelihood
    mapping(uint256 => uint256[]) likelihoodData;

    event GuineaPigFed(
        uint256 daysUntilHungry,
        uint256 daysUntilDead,
        address owner
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
        _grantRole(GAME_MANAGER, _msgSender());

        // 4 Races of guinea pig
        _races = ["PERU", "INTI", "ANDINO", "SINTETICO"];
        _speeds = [uint256(100), 105, 110, 115];
        _daysUntilHungry = [uint256(5), 6, 7, 8];
        _daysUntilDeath = [uint256(3), 4, 5, 6];
        _samiPoints = [uint256(9), 10, 11, 12];

        // Guniea pig purchase - likelihood
        _setLikelihoodAndPrices();
    }

    function validateMint(bytes memory) external pure returns (bool) {
        return true;
    }

    // /**
    //  * @dev Trigger when it is minted
    //  * @param _account:
    //  * @param _gender:
    //  * @param _race:
    //  * @param _idForJsonFile:
    //  * @param _guineaPigUuid:
    //  */
    function registerNft(bytes memory _data) external {
        (
            address _account,
            uint256 _gender,
            uint256 _race,
            uint256 _idForJsonFile,
            uint256 _price,
            uint256 _guineaPigUuid
        ) = abi.decode(
                _data,
                (address, uint256, uint256, uint256, uint256, uint256)
            );

        GuineaPigInfo memory _guineaPig = _getGuineaPigStruct(
            _gender,
            _race,
            _guineaPigUuid,
            _idForJsonFile,
            _account,
            _price
        );
        _uuidToGuineaPigInfo[_guineaPigUuid] = _guineaPig;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _guineaPigsIx[_guineaPigUuid] = current;
        listOfUuidGuineaPigs.push(_guineaPigUuid);
    }

    function transfer(
        address,
        address _newOwner,
        uint256 _guineaPigUuid
    ) external onlyRole(GAME_MANAGER) {
        GuineaPigInfo storage _guineaPig = _uuidToGuineaPigInfo[_guineaPigUuid];
        _guineaPig.owner = _newOwner;
    }

    /**
     * @dev Trigger when it is minted
     * @param _account:
     * @param _gender:
     * @param _race:
     * @param _idForJsonFile:
     * @param _guineaPigUuid:
     */
    function registerGuineaPig(
        address _account,
        uint256 _gender, // 0, 1
        uint256 _race, // 1 -> 4
        uint256 _idForJsonFile, // 1 -> 8
        uint256 _guineaPigUuid,
        uint256 _price
    ) external onlyRole(GAME_MANAGER) {
        GuineaPigInfo memory _guineaPig = _getGuineaPigStruct(
            _gender,
            _race,
            _guineaPigUuid,
            _idForJsonFile,
            _account,
            _price
        );
        _uuidToGuineaPigInfo[_guineaPigUuid] = _guineaPig;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _guineaPigsIx[_guineaPigUuid] = current;
        listOfUuidGuineaPigs.push(_guineaPigUuid);
    }

    function setDaysUntilHungry(uint256[4] memory _daysUntilHungry_)
        external
        onlyRole(GAME_MANAGER)
    {
        _daysUntilHungry = _daysUntilHungry_;
    }

    function setDaysUntilDeath(uint256[4] memory _daysUntilDeath_)
        external
        onlyRole(GAME_MANAGER)
    {
        _daysUntilDeath = _daysUntilDeath_;
    }

    function setSpeeds(uint256[4] memory _speeds_)
        external
        onlyRole(GAME_MANAGER)
    {
        _speeds = _speeds_;
    }

    function feedGuineaPig(uint256 _guineaPigUuid, uint256 _amountFood)
        external
        onlyRole(GAME_MANAGER)
    {
        GuineaPigInfo storage _guineaPig = _uuidToGuineaPigInfo[_guineaPigUuid];
        _guineaPig.feedingDate +=
            _guineaPig.daysUntilHungry *
            _amountFood *
            1 days;
        _guineaPig.burningDate +=
            _guineaPig.daysUntilHungry *
            _amountFood *
            1 days;

        emit GuineaPigFed(
            _guineaPig.feedingDate,
            _guineaPig.burningDate,
            _guineaPig.owner
        );
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////
    /**
     * @dev Returns the race and gender based on a random number from VRF
     * @param _raceRN is the random number (from VRF) used to calculate the race
     * @param _genderRN is the random number (from VRF) used to calculate the gender
     * @return Two integers are returned: race and gender respectively
     * @dev race   could be one of 1, 2, 3, 4 -> R1, R2, R3, R4
     * @dev gender could be one of 0, 1       -> Male, Female
     * uint256 public constant PERU_MALE = 1;
     * uint256 public constant INTI_MALE = 2;
     * uint256 public constant ANDINO_MALE = 3;
     * uint256 public constant SINTETICO_MALE = 4;
     * uint256 public constant PERU_FEMALE = 5;
     * uint256 public constant INTI_FEMALE = 6;
     * uint256 public constant ANDINO_FEMALE = 7;
     * uint256 public constant SINTETICO_FEMALE = 8;
     */
    function getRaceGenderGuineaPig(
        uint256 _ix,
        uint256 _raceRN, // [1, 100]
        uint256 _genderRN // [0, 1]
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            string memory
        )
    {
        // race between 1 and 4
        uint256 i;
        for (i = 0; i < likelihoodData[_ix].length; i++) {
            if (_raceRN <= likelihoodData[_ix][i]) break;
        }

        i += 1;
        assert(i >= 1 && i <= 4);

        // 0: male, 1: female
        uint256 id = i + _genderRN * 4;
        assert(id >= 1 && i <= 8);

        if (id == 1) return (_genderRN, i, id, "PERU MALE");
        else if (id == 2) return (_genderRN, i, id, "INTI MALE");
        else if (id == 3) return (_genderRN, i, id, "ANDINO MALE");
        else if (id == 4) return (_genderRN, i, id, "SINTETICO MALE");
        else if (id == 5) return (_genderRN, i, id, "PERU FEMALE");
        else if (id == 6) return (_genderRN, i, id, "INTI FEMALE");
        else if (id == 7) return (_genderRN, i, id, "ANDINO FEMALE");
        else return (_genderRN, i, id, "SINTETICO FEMALE");
    }

    function _setLikelihoodAndPrices() internal {
        likelihoodData[1] = [uint256(70), 85, 95, 100];
        likelihoodData[2] = [uint256(20), 50, 80, 100];
        likelihoodData[3] = [uint256(10), 30, 60, 100];
    }

    function getGuineaPigData(uint256 _uuid)
        external
        view
        returns (
            bool isGuineaPig,
            string memory gender,
            string memory race,
            uint256 speed,
            uint256 daysUntilHungry,
            uint256 daysUntilDeath,
            uint256 samiPoints,
            uint256 uuid,
            uint256 idForJsonFile,
            uint256 feedingDate,
            uint256 burningDate,
            uint256 wasBorn,
            address owner
        )
    {
        isGuineaPig = _uuidToGuineaPigInfo[_uuid].isGuineaPig;
        gender = _uuidToGuineaPigInfo[_uuid].gender;
        race = _uuidToGuineaPigInfo[_uuid].race;
        speed = _uuidToGuineaPigInfo[_uuid].speed;
        daysUntilHungry = _uuidToGuineaPigInfo[_uuid].daysUntilHungry;
        daysUntilDeath = _uuidToGuineaPigInfo[_uuid].daysUntilDeath;
        samiPoints = _uuidToGuineaPigInfo[_uuid].samiPoints;
        uuid = _uuidToGuineaPigInfo[_uuid].uuid;
        idForJsonFile = _uuidToGuineaPigInfo[_uuid].idForJsonFile;
        feedingDate = _uuidToGuineaPigInfo[_uuid].feedingDate;
        burningDate = _uuidToGuineaPigInfo[_uuid].burningDate;
        wasBorn = _uuidToGuineaPigInfo[_uuid].wasBorn;
        owner = _uuidToGuineaPigInfo[_uuid].owner;
    }

    function getListOfGuineaPigs()
        external
        view
        returns (GuineaPigInfo[] memory listOfGuineaPigs)
    {
        listOfGuineaPigs = new GuineaPigInfo[](listOfUuidGuineaPigs.length);
        for (uint256 ix = 0; ix < listOfUuidGuineaPigs.length; ix++) {
            listOfGuineaPigs[ix] = _uuidToGuineaPigInfo[
                listOfUuidGuineaPigs[ix]
            ];
        }
    }

    function getGuineaPigWithUuid(uint256 _guineaPigUuid)
        external
        view
        returns (GuineaPigInfo memory)
    {
        return _uuidToGuineaPigInfo[_guineaPigUuid];
    }

    function setPachacuyInfoAddress(address _pachacuyInfo)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachacuyInfo = IPachacuyInfo(_pachacuyInfo);
    }

    function _getGuineaPigStruct(
        uint256 _gender,
        uint256 _race,
        uint256 _uuid,
        uint256 _tokenId,
        address _account,
        uint256 _price
    ) internal view returns (GuineaPigInfo memory) {
        return
            GuineaPigInfo({
                isGuineaPig: true,
                gender: _gender == 0 ? "MALE" : "FEMALE",
                race: _races[_race - 1],
                speed: _speeds[_race - 1],
                daysUntilHungry: _daysUntilHungry[_race - 1],
                daysUntilDeath: _daysUntilDeath[_race - 1],
                samiPoints: _samiPoints[_race - 1],
                uuid: _uuid,
                idForJsonFile: _tokenId,
                feedingDate: block.timestamp +
                    (_daysUntilHungry[_race - 1] * 1 days),
                burningDate: block.timestamp +
                    (_daysUntilHungry[_race - 1] * 1 days) +
                    (_daysUntilDeath[_race - 1] * 1 days),
                wasBorn: block.timestamp,
                owner: _account,
                price: _price
            });
    }

    function tokenUri(string memory _prefix, uint256 _guineaPigUuid)
        external
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _prefix,
                    _uuidToGuineaPigInfo[_guineaPigUuid]
                        .idForJsonFile
                        .toString(),
                    ".json"
                )
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
