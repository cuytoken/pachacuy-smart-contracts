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
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

// Interfaces
import "../tatacuy/ITatacuy.sol";
import "../wiracocha/IWiracocha.sol";
import "../chakra/IChakra.sol";
import "../hatunwasi/IHatunWasi.sol";
import "../info/IPachacuyInfo.sol";
import "../misayWasi/IMisayWasi.sol";
import "../guineapig/IGuineaPig.sol";
import "../pacha/IPacha.sol";
import "../qhatuwasi/IQhatuWasi.sol";

/// @custom:security-contact lee@cuytoken.com
contract NftProducerPachacuy is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    ERC1155SupplyUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    IPachacuyInfo pachacuyInfo;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    using StringsUpgradeable for uint256;

    // NFT types
    bytes32 public constant TATACUY = keccak256("TATACUY");
    bytes32 public constant WIRACOCHA = keccak256("WIRACOCHA");
    bytes32 public constant CHAKRA = keccak256("CHAKRA");
    bytes32 public constant HATUNWASI = keccak256("HATUNWASI");
    bytes32 public constant MISAYWASI = keccak256("MISAYWASI");
    bytes32 public constant QHATUWASI = keccak256("QHATUWASI");
    bytes32 public constant RAFFLE = keccak256("RAFFLE");
    bytes32 public constant GUINEAPIG = keccak256("GUINEAPIG");
    bytes32 public constant PACHA = keccak256("PACHA");
    bytes32 public constant TICKETRAFFLE = keccak256("TICKETRAFFLE");

    event Uuid(uint256 uuid);
    event UuidAndAmount(uint256 uuid, uint256 amount);

    // transferMode: purchased | transferred
    // Pacha data
    // struct PachaPassdata {
    //     bool isPachaPass;
    //     uint256 pachaUuid;
    //     uint256 typeOfDistribution;
    //     uint256 uuid;
    //     uint256 cost;
    //     string transferMode;
    // }
    // // uuid => Pacha Pass
    // mapping(uint256 => PachaPassdata) internal _uuidToPachaPassData;

    // Map owner -> uuid[]
    mapping(address => uint256[]) internal _ownerToUuids;

    // Token name
    string internal _name;
    // Token symbol
    string internal _symbol;
    // Token prefix
    string internal _prefix;

    // Map uuid with NFT type
    mapping(uint256 => bytes32) internal _nftTypes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory name_, string memory symbol_)
        public
        initializer
    {
        _prefix = "ipfs://QmbbGgo93M6yr5WSUMj53SWN2vC7L6aMS1GZSPNkVRY8e4/";

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
        _grantRole(GAME_MANAGER, _msgSender());

        // starts counter at one
        _tokenIdCounter.increment();
    }

    function mintGuineaPigNft(
        address _account,
        uint256 _gender, // 0, 1
        uint256 _race, // 1 -> 4
        uint256 _idForJsonFile // 1 -> 8
    ) public onlyRole(MINTER_ROLE) {
        // Creates a UUID for each mint
        uint256 uuid = _tokenIdCounter.current();
        _mint(_account, uuid, 1, "");

        // Map owner -> uuid[]
        // save in list of uuids for owner
        _ownerToUuids[_account].push(uuid);

        // save type of uuid minted
        _nftTypes[uuid] = GUINEAPIG;

        // Save info in Guinea Pig SC
        IGuineaPig(pachacuyInfo.guineaPigAddress()).registerGuineaPig(
            _account,
            _gender,
            _race,
            _idForJsonFile,
            uuid
        );

        _setApprovalForAll(_account, address(this), true);

        _tokenIdCounter.increment();
        emit Uuid(uuid);
    }

    function mintLandNft(
        address _account,
        uint256 _idForJsonFile, // comes from front-end 1 -> 697
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        // Veryfies that location is not taken already
        require(
            !IPacha(pachacuyInfo.pachaAddress()).isPachaAlreadyTaken(
                _idForJsonFile
            ),
            "NFP: location taken"
        );

        // Creates a UUID for each mint
        uint256 uuid = _tokenIdCounter.current();
        _mint(_account, uuid, 1, data);

        // Map owner -> uuid[]
        _ownerToUuids[_account].push(uuid);

        // save type of uuid minted
        _nftTypes[uuid] = PACHA;

        // Map uuid -> Guinea Pig Struct
        IPacha(pachacuyInfo.pachaAddress()).registerPacha(
            _account,
            _idForJsonFile,
            uuid
        );

        _tokenIdCounter.increment();
        emit Uuid(uuid);
    }

    function mintWiracocha(uint256 _pachaUuid) external returns (uint256) {
        // validate that _account is an owner of that pacha
        require(balanceOf(_msgSender(), _pachaUuid) > 0, "NFP: No pacha found");

        // validate that there is not a Wiracocha at this pacha uuid
        require(
            !IWiracocha(pachacuyInfo.wiracochaAddress())
                .getWiracochaInfoForAccount(_msgSender(), _pachaUuid)
                .hasWiracocha,
            "NFP: Pacha has a Wiracocha already"
        );

        uint256 uuid = _tokenIdCounter.current();
        _mint(_msgSender(), uuid, 1, "");

        // save in list of uuids for owner
        _ownerToUuids[_msgSender()].push(uuid);

        // save type of uuid minted
        _nftTypes[uuid] = WIRACOCHA;

        // Save info in Tatacuy SC
        // uuid =>  wiracochaUuid
        IWiracocha(pachacuyInfo.wiracochaAddress()).registerWiracocha(
            _msgSender(),
            _pachaUuid,
            uuid,
            ""
        );

        _tokenIdCounter.increment();

        emit Uuid(uuid);
        return uuid;
    }

    function mintTatacuy(uint256 _pachaUuid) external returns (uint256) {
        // validate that _account is an owner of that pacha
        require(balanceOf(_msgSender(), _pachaUuid) > 0, "NFP: No pacha found");

        // validate that there is not a Tatacuy at this pacha uuid
        require(
            !ITatacuy(pachacuyInfo.tatacuyAddress())
                .getTatacuyInfoForAccount(_msgSender(), _pachaUuid)
                .hasTatacuy,
            "NFP: Pacha has a Tatacuy already"
        );

        uint256 uuid = _tokenIdCounter.current();
        _mint(_msgSender(), uuid, 1, "");

        // save in list of uuids for owner
        _ownerToUuids[_msgSender()].push(uuid);

        // save type of uuid minted
        _nftTypes[uuid] = TATACUY;

        // Save info in Tatacuy SC
        // uuid =>  tatacuyUuid
        ITatacuy(pachacuyInfo.tatacuyAddress()).registerTatacuy(
            _msgSender(),
            _pachaUuid,
            uuid,
            ""
        );

        _tokenIdCounter.increment();

        emit Uuid(uuid);
        return uuid;
    }

    function mintChakra(
        address _account,
        uint256 _pachaUuid,
        uint256 _chakraPrice
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        // validate that _account is an owner of that pacha
        require(balanceOf(_account, _pachaUuid) > 0, "NFP: No pacha found");

        uint256 uuid = _tokenIdCounter.current();
        _mint(_account, uuid, 1, "");

        // save in list of uuids for owner
        _ownerToUuids[_account].push(uuid);

        // save type of uuid minted
        _nftTypes[uuid] = CHAKRA;

        // Save info in Chakra SC
        IChakra(pachacuyInfo.chakraAddress()).registerChakra(
            _account,
            _pachaUuid,
            uuid,
            _chakraPrice
        );

        _tokenIdCounter.increment();
        emit Uuid(uuid);
        return uuid;
    }

    function purchaseFood(
        uint256 _chakraUuid,
        uint256 _amountFood,
        uint256 _guineaPigUuid
    ) external onlyRole(GAME_MANAGER) returns (uint256 availableFood) {
        // update Guinea Pig life span
        IGuineaPig(pachacuyInfo.guineaPigAddress()).feedGuineaPig(
            _guineaPigUuid
        );

        availableFood = IChakra(pachacuyInfo.chakraAddress())
            .consumeFoodFromChakra(_chakraUuid, _amountFood);
    }

    function burnChakra(uint256 _chakraUuid) external {
        _burn(_msgSender(), _chakraUuid, 1);

        IChakra(pachacuyInfo.chakraAddress()).burnChakra(_chakraUuid);
    }

    function mintHatunWasi(uint256 _pachaUuid) external returns (uint256) {
        // validate that _account is an owner of that pacha
        require(balanceOf(_msgSender(), _pachaUuid) > 0, "NFP: No pacha found");

        // validate that there is not a Wiracocha at this pacha uuid
        IHatunWasi hw = IHatunWasi(pachacuyInfo.hatunWasiAddress());
        require(
            !hw.getAHatunWasi(_msgSender(), _pachaUuid).hasHatunWasi,
            "NFP: Hatun Wasi exists"
        );

        uint256 uuid = _tokenIdCounter.current();
        _mint(_msgSender(), uuid, 1, "");

        // save in list of uuids for owner
        _ownerToUuids[_msgSender()].push(uuid);

        // save type of uuid minted
        _nftTypes[uuid] = HATUNWASI;

        // Save info in Hatun Wasi SC
        // uuid =>  hatunWasiUuid
        hw.registerHatunWasi(_msgSender(), _pachaUuid, uuid);

        _tokenIdCounter.increment();

        emit Uuid(uuid);
        return uuid;
    }

    function mintMisayWasi(
        address _account,
        uint256 _pachaUuid,
        uint256 _misayWasiPrice
    ) external onlyRole(GAME_MANAGER) {
        // validate that _account is an owner of that pacha
        require(balanceOf(_account, _pachaUuid) > 0, "NFP: No pacha found");

        uint256 uuid = _tokenIdCounter.current();
        _mint(_msgSender(), uuid, 1, "");

        // save in list of uuids for owner
        _ownerToUuids[_msgSender()].push(uuid);

        // save type of uuid minted
        _nftTypes[uuid] = MISAYWASI;

        // Save info in Misay Wasi SC
        IMisayWasi(pachacuyInfo.misayWasiAddress()).registerMisayWasi(
            _account,
            _pachaUuid,
            uuid,
            _misayWasiPrice
        );

        _tokenIdCounter.increment();

        emit Uuid(uuid);
    }

    function createTicketIdRaffle()
        external
        onlyRole(GAME_MANAGER)
        returns (uint256 _raffleUuid)
    {
        uint256 uuid = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // save type of uuid minted
        _nftTypes[uuid] = TICKETRAFFLE;

        return uuid;
    }

    function purchaseTicketRaffle(
        address _account,
        uint256 _ticketUuid,
        uint256 _misayWasiUuid,
        uint256 _amountOfTickets
    ) external onlyRole(GAME_MANAGER) {
        // has tickets already?
        bool hasBoughtBefore = balanceOf(_account, _ticketUuid) > 0;

        // mint the tickets of the raffle
        _mint(_account, _ticketUuid, _amountOfTickets, "");

        // save in list of uuids for owner
        _ownerToUuids[_account].push(_ticketUuid);

        IMisayWasi(pachacuyInfo.misayWasiAddress()).registerTicketPurchase(
            _account,
            _misayWasiUuid,
            _amountOfTickets,
            hasBoughtBefore
        );
        emit UuidAndAmount(_ticketUuid, balanceOf(_account, _ticketUuid));
    }

    function mintQhatuWasi(
        uint256 _pachaUuid,
        address _account,
        uint256 _qhatuWasiPrice
    ) external onlyRole(MINTER_ROLE) {
        // validate that _account is an owner of that pacha
        require(balanceOf(_account, _pachaUuid) > 0, "NFP: No pacha found");

        uint256 uuid = _tokenIdCounter.current();
        _mint(_account, uuid, 1, "");

        // save in list of uuids for owner
        _ownerToUuids[_account].push(uuid);

        // save type of uuid minted
        _nftTypes[uuid] = QHATUWASI;

        IQhatuWasi(pachacuyInfo.qhatuWasiAddress()).registerQhatuWasi(
            uuid,
            _account,
            _qhatuWasiPrice
        );

        emit Uuid(uuid);
        _tokenIdCounter.increment();
    }

    // function mintPachaPassNft(
    //     address _account,
    //     uint256 _landUuid,
    //     uint256 _uuidPachaPass,
    //     uint256 _typeOfDistribution,
    //     uint256 _price,
    //     string memory _transferMode
    // ) public onlyRole(MINTER_ROLE) {
    //     _mintPachaPassNft(
    //         _account,
    //         _landUuid,
    //         _uuidPachaPass,
    //         _typeOfDistribution,
    //         _price,
    //         _transferMode
    //     );
    // }

    // function mintPachaPassNftAsOwner(
    //     address[] memory _accounts,
    //     uint256 _landUuid
    // ) external {
    //     LandData memory landData = _uuidToLandData[_landUuid];
    //     require(landData.owner == _msgSender(), "Nft P: Not the owner");
    //     require(landData.isLand, "Nft P: Not a land");
    //     require(!landData.isPublic, "Nft P: Land must be private");
    //     require(landData.pachaPassUuid > 0, "Nft P: PachaPass do not exist");

    //     for (uint256 i = 0; i < _accounts.length; i++) {
    //         _mintPachaPassNft(
    //             _accounts[i],
    //             _landUuid,
    //             landData.pachaPassUuid,
    //             landData.typeOfDistribution,
    //             landData.pachaPassPrice,
    //             "transferred"
    //         );
    //     }
    // }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 uuid,
    //     uint256 amount,
    //     bytes memory data
    // ) public override {
    //     require(
    //         from == _msgSender() || isApprovedForAll(from, _msgSender()),
    //         "ERC1155: caller is not owner nor approved"
    //     );

    //     if (_uuidToGuineaPigData[uuid].isGuineaPig) {
    //         _uuidToGuineaPigData[uuid].owner = to;
    //     } else if (_uuidToLandData[uuid].isLand) {
    //         _uuidToLandData[uuid].owner = to;
    //         // Transfer all elements within a Land
    //         // IMPLEMENT
    //     }

    //     // remove uuid from _ownerToUuids => uuid[]
    //     _rmvElFromOwnerToUuids(from, uuid);

    //     // add that uuid to new owner's array
    //     _ownerToUuids[to].push(uuid);

    //     _safeTransferFrom(from, to, uuid, amount, data);
    // }

    // function burn(
    //     address account,
    //     uint256 uuid,
    //     uint256 value
    // ) public virtual override {
    //     require(
    //         account == _msgSender() || isApprovedForAll(account, _msgSender()),
    //         "ERC1155: caller is not owner nor approved"
    //     );

    //     if (_uuidToGuineaPigData[uuid].isGuineaPig) {
    //         value = 1;
    //         delete _uuidToGuineaPigData[uuid];
    //     } else if (_uuidToLandData[uuid].isLand) {
    //         value = 1;
    //         delete _uuidToLandData[uuid];
    //     }

    //     // remove uuid from _ownerToUuids => uuid[]
    //     _rmvElFromOwnerToUuids(account, uuid);

    //     _burn(account, uuid, value);
    // }

    ///////////////////////////////////////////////////////////////
    ////                   HELPERS FUNCTIONS                   ////
    ///////////////////////////////////////////////////////////////
    // function isGuineaPigAllowedInPacha(address _account, uint256 _landUuid)
    //     external
    //     view
    //     returns (bool)
    // {
    //     LandData memory landData = _uuidToLandData[_landUuid];

    //     if (!landData.isLand) return false;
    //     if (landData.isPublic) return true;

    //     // All private land must have a uuid for its pachapass
    //     require(landData.pachaPassUuid != 0, "NFP: Uuid's pachapass missing");
    //     if (balanceOf(_account, landData.pachaPassUuid) > 0) {
    //         return true;
    //     } else return false;
    // }

    // function getListOfNftsPerAccount(address _account)
    //     external
    //     view
    //     returns (
    //         uint256[] memory guineaPigs,
    //         uint256[] memory lands,
    //         uint256[] memory pachaPasses
    //     )
    // {
    //     {
    //         uint256[] memory _uuidsList = _ownerToUuids[_account];
    //         uint256 length = _uuidsList.length;

    //         guineaPigs = new uint256[](length);
    //         lands = new uint256[](length);
    //         pachaPasses = new uint256[](length);

    //         uint256 g = 0;
    //         uint256 l = 0;
    //         uint256 h = 0;

    //         for (uint256 i = 0; i < length; i++) {
    //             if (_uuidToGuineaPigData[_uuidsList[i]].isGuineaPig) {
    //                 guineaPigs[g] = _uuidsList[i];
    //                 ++g;
    //             } else if (_uuidToLandData[_uuidsList[i]].isLand) {
    //                 lands[l] = _uuidsList[i];
    //                 ++l;
    //             }
    //             // else if (_uuidToPachaPassData[_uuidsList[i]].isPachaPass) {
    //             //     pachaPasses[h] = _uuidsList[i];
    //             //     ++h;
    //             // }
    //         }
    //     }
    // }

    // function getPachaPassData(uint256 _uuid)
    //     external
    //     view
    //     returns (
    //         bool isPachaPass,
    //         uint256 pachaUuid,
    //         uint256 typeOfDistribution,
    //         uint256 uuid,
    //         uint256 cost,
    //         string memory transferMode
    //     )
    // {
    //     isPachaPass = _uuidToPachaPassData[_uuid].isPachaPass;
    //     pachaUuid = _uuidToPachaPassData[_uuid].pachaUuid;
    //     typeOfDistribution = _uuidToPachaPassData[_uuid].typeOfDistribution;
    //     uuid = _uuidToPachaPassData[_uuid].uuid;
    //     cost = _uuidToPachaPassData[_uuid].cost;
    //     transferMode = _uuidToPachaPassData[_uuid].transferMode;
    // }

    function _compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // function _rmvElFromOwnerToUuids(address _account, uint256 _uuid) internal {
    //     require(_ownerToUuids[_account].length > 0, "NFP: Array is empty");

    //     if (_ownerToUuids[_account].length == 1) {
    //         if (_ownerToUuids[_account][0] == _uuid) {
    //             _ownerToUuids[_account].pop();
    //             return;
    //         } else {
    //             revert("NFP: Not found");
    //         }
    //     }

    //     // find the index of _uuid
    //     uint256 i;
    //     for (i = 0; i < _ownerToUuids[_account].length; i++) {
    //         if (_ownerToUuids[_account][i] == _uuid) break;
    //     }
    //     require(i != _ownerToUuids[_account].length, "NFP: Not found");

    //     // remove the element
    //     _ownerToUuids[_account][i] = _ownerToUuids[_account][
    //         _ownerToUuids[_account].length - 1
    //     ];
    //     _ownerToUuids[_account].pop();
    // }

    function getListOfUuidsPerAccount(address _account)
        external
        view
        returns (uint256[] memory _listOfUuids, bytes32[] memory _listOfTypes)
    {
        _listOfUuids = _ownerToUuids[_account];
        _listOfTypes = new bytes32[](_listOfUuids.length);
        for (uint256 ix = 0; ix < _listOfUuids.length; ix++) {
            _listOfTypes[ix] = _nftTypes[_listOfUuids[ix]];
        }
    }

    function setPachacuyInfoaddress(address _pachacuyInfo)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachacuyInfo = IPachacuyInfo(_pachacuyInfo);
    }

    ///////////////////////////////////////////////////////////////
    ////               ERC1155 STANDARD FUNCTIONS              ////
    ///////////////////////////////////////////////////////////////
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _prefix = newuri;
        _setURI(newuri);
    }

    function tokenURI(uint256 _uuid) public view returns (string memory) {
        // require(exists(_uuid), "NFP: Token has not been minted.");

        // uint256 idForJsonFile = _uuidToJsonFile[_uuid];

        string memory fileName;
        // if (_uuidToGuineaPigData[_uuid].isGuineaPig) {
        //     fileName = string(
        //         abi.encodePacked(_prefix, idForJsonFile.toString(), ".json")
        //     );
        // } else if (_uuidToLandData[_uuid].isLand) {
        //     fileName = string(
        //         abi.encodePacked(
        //             _prefix,
        //             "PACHA",
        //             idForJsonFile.toString(),
        //             ".json"
        //         )
        //     );
        // }
        // //  else if (_uuidToPachaPassData[_uuid].isPachaPass) {
        // //     fileName = string(abi.encodePacked(_prefix, "PACHAPASS.json"));
        // // }

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
    // function mintBatch(
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) public onlyRole(MINTER_ROLE) {
    //     _mintBatch(to, ids, amounts, data);
    // }

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
