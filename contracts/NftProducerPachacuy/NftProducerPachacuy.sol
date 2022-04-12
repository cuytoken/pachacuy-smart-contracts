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
////                                            NFT PRODUCER PACHACUY                                            ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract NftProducerPachacuy is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    ERC1155SupplyUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    using StringsUpgradeable for uint256;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    // Guinea pig: token IDs
    uint256 public constant PERU_MALE = 1;
    uint256 public constant INTI_MALE = 2;
    uint256 public constant ANDINO_MALE = 3;
    uint256 public constant SINTETICO_MALE = 4;
    uint256 public constant PERU_FEMALE = 5;
    uint256 public constant INTI_FEMALE = 6;
    uint256 public constant ANDINO_FEMALE = 7;
    uint256 public constant SINTETICO_FEMALE = 8;

    // Pacha: token ID
    uint256 public constant PACHA = 9;

    // Guinea pig data
    struct GuineaPigData {
        bool isGuineaPig;
        string race;
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
    }
    // uuid => GuineaPig
    mapping(uint256 => GuineaPigData) internal _uuidToGuineaPigData;

    // Land data
    struct LandData {
        bool isLand;
        bool isPublic;
        uint256 uuid;
        uint256 idForJsonFile;
        uint256 wasPurchased;
        uint256 location;
        address owner;
    }
    // uuid => Land
    mapping(uint256 => LandData) internal _uuidToLandData;
    mapping(uint256 => bool) internal _idsForJsonFile;

    // Map uuid -> token id
    mapping(uint256 => uint256) internal _uuidToTokenId;
    // Map owner -> uuid[]
    mapping(address => uint256[]) internal _ownerToUuids;

    // Token name
    string internal _name;
    // Token symbol
    string internal _symbol;
    // Token prefix
    string internal _prefix;

    // Guinea Pig races
    string[4] private _races;
    uint256[4] private _speeds;
    uint256[4] private _daysUntilHungry;
    uint256[4] private _daysUntilDeath;
    uint256[4] private _samiPoints;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory name_, string memory symbol_)
        public
        initializer
    {
        _prefix = "ipfs://QmWQrpftdoXDq7f1vmKwmg5aeuorcXa1JcvwyqnU7VgCBr/";

        __ERC1155_init(_prefix);
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        _name = name_;
        _symbol = symbol_;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(URI_SETTER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());

        // 4 Races of guinea pig
        _races = ["PERU", "INTI", "ANDINO", "SINTETICO"];
        _speeds = [uint256(100), 105, 110, 115];
        _daysUntilHungry = [uint256(5), 6, 7, 8];
        _daysUntilDeath = [uint256(3), 4, 5, 6];
        _samiPoints = [uint256(9), 10, 11, 12];
    }

    function mintGuineaPigNft(
        address account,
        uint256 race, // 1 -> 4
        uint256 idForJsonFile, // 1 -> 8
        bytes memory data
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        // Creates a UUID for each mint
        uint256 uuid = _tokenIdCounter.current();

        // Map uuid -> idForJsonFile
        _uuidToTokenId[uuid] = idForJsonFile;

        // Map owner -> uuid[]
        _ownerToUuids[account].push(uuid);

        // Map uuid -> Guinea Pig Struct
        _uuidToGuineaPigData[uuid] = _getGuinieaPigStruct(
            race,
            uuid,
            idForJsonFile,
            account
        );
        uint256 amount = 1;
        _mint(account, uuid, amount, data);
        _setApprovalForAll(account, address(this), true);

        _tokenIdCounter.increment();

        return uuid;
    }

    function mintLandNft(
        address account,
        uint256 idForJsonFile, // comes from front-end 1 -> 697
        bytes memory data
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        // Veryfies that location is not taken already
        require(
            !_idsForJsonFile[idForJsonFile],
            "Nft P.: location already taken"
        );

        // Creates a UUID for each mint
        uint256 uuid = _tokenIdCounter.current();

        // Map uuid -> idForJsonFile
        _uuidToTokenId[uuid] = idForJsonFile;

        // Mark that space of land as purchased
        _idsForJsonFile[idForJsonFile] = true;

        // Map owner -> uuid[]
        _ownerToUuids[account].push(uuid);

        // Map uuid -> Guinea Pig Struct
        _uuidToLandData[uuid] = LandData({
            isLand: true,
            isPublic: true,
            uuid: uuid,
            location: idForJsonFile,
            idForJsonFile: idForJsonFile,
            owner: account,
            wasPurchased: block.timestamp
        });

        uint256 amount = 1;
        _mint(account, uuid, amount, data);
        _setApprovalForAll(account, address(this), true);

        _tokenIdCounter.increment();

        return uuid;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 uuid,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        if (_uuidToGuineaPigData[uuid].isGuineaPig) {
            _uuidToGuineaPigData[uuid].owner = to;
        } else if (_uuidToLandData[uuid].isLand) {
            _uuidToLandData[uuid].owner = to;
            // Transfer all elements within a Land
            // IMPLEMENT
        }

        // remove uuid from _ownerToUuids => uuid[]
        _rmvElFromOwnerToUuids(from, uuid);

        // add that uuid to new owner's array
        _ownerToUuids[to].push(uuid);

        _safeTransferFrom(from, to, uuid, amount, data);
    }

    function burn(
        address account,
        uint256 uuid,
        uint256 value
    ) public virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        if (_uuidToGuineaPigData[uuid].isGuineaPig) {
            value = 1;
            delete _uuidToGuineaPigData[uuid];
        } else if (_uuidToLandData[uuid].isLand) {
            value = 1;
            delete _uuidToLandData[uuid];
        }

        // remove uuid from _ownerToUuids => uuid[]
        _rmvElFromOwnerToUuids(account, uuid);

        _burn(account, uuid, value);
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPERS FUNCTIONS                   ////
    ///////////////////////////////////////////////////////////////
    function _getGuinieaPigStruct(
        uint256 _race,
        uint256 _uuid,
        uint256 _tokenId,
        address _account
    ) internal view returns (GuineaPigData memory) {
        return
            GuineaPigData({
                isGuineaPig: true,
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
                owner: _account
            });
    }

    function getListOfNftsPerAccount(address _account)
        external
        view
        returns (uint256[] memory guineaPigs, uint256[] memory lands)
    {
        {
            uint256[] memory _uuidsList = _ownerToUuids[_account];
            uint256 length = _uuidsList.length;

            guineaPigs = new uint256[](length);
            lands = new uint256[](length);

            uint256 g = 0;
            uint256 l = 0;

            for (uint256 i = 0; i < length; i++) {
                if (_uuidToGuineaPigData[_uuidsList[i]].isGuineaPig) {
                    guineaPigs[g] = _uuidsList[i];
                    ++g;
                } else if (_uuidToLandData[_uuidsList[i]].isLand) {
                    lands[l] = _uuidsList[i];
                    ++l;
                }
            }
        }
    }

    function getGuineaPigData(uint256 _uuid)
        external
        view
        returns (
            bool isGuineaPig,
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
        require(exists(_uuid), "Nft P.: uuid does not exist");
        isGuineaPig = _uuidToGuineaPigData[_uuid].isGuineaPig;
        race = _uuidToGuineaPigData[_uuid].race;
        speed = _uuidToGuineaPigData[_uuid].speed;
        daysUntilHungry = _uuidToGuineaPigData[_uuid].daysUntilHungry;
        daysUntilDeath = _uuidToGuineaPigData[_uuid].daysUntilDeath;
        samiPoints = _uuidToGuineaPigData[_uuid].samiPoints;
        uuid = _uuidToGuineaPigData[_uuid].uuid;
        idForJsonFile = _uuidToGuineaPigData[_uuid].idForJsonFile;
        feedingDate = _uuidToGuineaPigData[_uuid].feedingDate;
        burningDate = _uuidToGuineaPigData[_uuid].burningDate;
        wasBorn = _uuidToGuineaPigData[_uuid].wasBorn;
        owner = _uuidToGuineaPigData[_uuid].owner;
    }

    function getLandData(uint256 _uuid)
        external
        view
        returns (
            bool isLand,
            bool isPublic,
            uint256 uuid,
            uint256 location,
            uint256 idForJsonFile,
            uint256 wasPurchased,
            address owner
        )
    {
        isLand = _uuidToLandData[_uuid].isLand;
        isPublic = _uuidToLandData[_uuid].isPublic;
        uuid = _uuidToLandData[_uuid].uuid;
        location = _uuidToLandData[_uuid].location;
        idForJsonFile = _uuidToLandData[_uuid].idForJsonFile;
        wasPurchased = _uuidToLandData[_uuid].wasPurchased;
        owner = _uuidToLandData[_uuid].owner;
    }

    function _compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function _rmvElFromOwnerToUuids(address _account, uint256 _uuid) internal {
        require(_ownerToUuids[_account].length > 0, "Nft P.: Array is empty");

        if (_ownerToUuids[_account].length == 1) {
            if (_ownerToUuids[_account][0] == _uuid) {
                _ownerToUuids[_account].pop();
                return;
            } else {
                revert("Nft P.: Not found");
            }
        }

        // find the index of _uuid
        uint256 i;
        for (i = 0; i < _ownerToUuids[_account].length; i++) {
            if (_ownerToUuids[_account][i] == _uuid) break;
        }
        require(i != _ownerToUuids[_account].length, "Nft P.: Not found");

        // remove the element
        _ownerToUuids[_account][i] = _ownerToUuids[_account][
            _ownerToUuids[_account].length - 1
        ];
        _ownerToUuids[_account].pop();
    }

    ///////////////////////////////////////////////////////////////
    ////               ERC1155 STANDARD FUNCTIONS              ////
    ///////////////////////////////////////////////////////////////
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _prefix = newuri;
        _setURI(newuri);
    }

    function tokenURI(uint256 _uuid) public view returns (string memory) {
        require(exists(_uuid), "Nft P.: Token has not been minted.");

        uint256 idForJsonFile = _uuidToTokenId[_uuid];

        string memory fileName;
        if (_uuidToGuineaPigData[_uuid].isGuineaPig) {
            fileName = string(
                abi.encodePacked(_prefix, idForJsonFile.toString(), ".json")
            );
        } else if (_uuidToLandData[_uuid].isLand) {
            fileName = string(
                abi.encodePacked(
                    _prefix,
                    "PACHA",
                    idForJsonFile.toString(),
                    ".json"
                )
            );
        }

        return bytes(_prefix).length > 0 ? fileName : "";
    }

    function uri(uint256 _uuid) public view override returns (string memory) {
        return tokenURI(_uuid);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Have a look later
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
