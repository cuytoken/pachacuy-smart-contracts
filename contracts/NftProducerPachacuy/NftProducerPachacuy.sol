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

    // Guinea pig races and genders ordered by index
    uint256 private constant PERU_MALE = 1;
    uint256 private constant INTI_MALE = 2;
    uint256 private constant ANDINO_MALE = 3;
    uint256 private constant SINTETICO_MALE = 4;
    uint256 private constant PERU_FEMALE = 5;
    uint256 private constant INTI_FEMALE = 6;
    uint256 private constant ANDINO_FEMALE = 7;
    uint256 private constant SINTETICO_FEMALE = 8;

    // baseUri
    string public baseUri;

    // Guinea pig data
    struct GuineaPigData {
        uint256 velocity;
        uint256 foodLasting;
        uint256 daysUntilDeath;
        uint256 samiPoints;
    }
    mapping(uint256 => GuineaPigData) public guineaPigData;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        baseUri = "ipfs://QmcjUVjmJeHVsThfoUhkwGmgDVbmPRqnYz1CUmcQTeR5YU/";

        __ERC1155_init(baseUri);
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(URI_SETTER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());

        _setGuineaPigData();

        // Starts at counter 1
        if (_tokenIdCounter.current() == 0) _tokenIdCounter.increment();
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPERS FUNCTIONS                   ////
    ///////////////////////////////////////////////////////////////
    function _setGuineaPigData() internal {
        guineaPigData[1] = GuineaPigData({
            velocity: 100,
            foodLasting: 5,
            daysUntilDeath: 3,
            samiPoints: 9
        });
        guineaPigData[2] = GuineaPigData({
            velocity: 105,
            foodLasting: 6,
            daysUntilDeath: 4,
            samiPoints: 10
        });
        guineaPigData[3] = GuineaPigData({
            velocity: 110,
            foodLasting: 7,
            daysUntilDeath: 5,
            samiPoints: 11
        });
        guineaPigData[4] = GuineaPigData({
            velocity: 115,
            foodLasting: 8,
            daysUntilDeath: 6,
            samiPoints: 12
        });
    }

    function getListOfNftsPerAccount(address _account)
        external
        view
        returns (uint256[] memory)
    {
        // 1 -> 8
        uint256 start = 1;
        uint256 end = 8;

        uint256[] memory nfts = new uint256[](end - start + 1);

        for (uint256 i = start; i <= end; i++) {
            nfts[i] = balanceOf(_account, i);
        }
        return nfts;
    }

    function getGuineaPigData(uint256 _ix)
        external
        view
        returns (
            uint256 velocity,
            uint256 foodLasting,
            uint256 daysUntilDeath,
            uint256 samiPoints
        )
    {
        velocity = guineaPigData[_ix].velocity;
        foodLasting = guineaPigData[_ix].foodLasting;
        daysUntilDeath = guineaPigData[_ix].daysUntilDeath;
        samiPoints = guineaPigData[_ix].samiPoints;
    }

    ///////////////////////////////////////////////////////////////
    ////               ERC1155 STANDARD FUNCTIONS              ////
    ///////////////////////////////////////////////////////////////
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        baseUri = newuri;
        _setURI(newuri);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return
            bytes(baseUri).length > 0
                ? string(abi.encodePacked(baseUri, tokenId.toString(), ".json"))
                : "";
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            bytes(baseUri).length > 0
                ? string(abi.encodePacked(baseUri, tokenId.toString(), ".json"))
                : "";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
        _setApprovalForAll(account, address(this), true);
    }

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
