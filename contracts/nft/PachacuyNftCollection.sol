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
////                                             LAND OF GUINEA PIGS                                             ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract PachacuyNftCollection is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    using StringsUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public maxSupply;
    uint256 public nftCurrentPrice;

    // BUSD token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public busdToken;

    // custodian wallet for busd
    address public custodianWallet;

    // baseUri
    string public baseUri;

    // whitelist
    struct Whitelister {
        address account;
        bool claimed;
        bool inWhitelist;
    }
    mapping(address => Whitelister) whitelist;

    // Reserved NFT
    mapping(uint256 => bool) reservedNft;
    uint256[] public listOfReservedNft;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _nftCurrentPrice,
        address _busdAddress,
        address _custodianWallet,
        string memory _baseUri
    ) public initializer {
        __ERC721_init(_tokenName, _tokenSymbol);
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());

        maxSupply = _maxSupply;
        nftCurrentPrice = _nftCurrentPrice;
        busdToken = IERC20Upgradeable(_busdAddress);
        custodianWallet = _custodianWallet;
        baseUri = _baseUri;
    }

    /**
     * @dev Delivers to an account a random NFT
     * @dev IMPORTANT: Without an NFT ID, this function skips minting reserved NFTs
     * @dev Only accounts with Minter Role could call this function
     * @param to: Account to receive the NFT
     */
    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        deliverNft(to);
    }

    /**
     * @dev Delivers to an account an specific NFT by using its ID
     * @dev IMPORTANT: This is the only way to deliver a reserved NFT by using its ID
     * @dev Only accounts with Minter Role could call this function
     * @param to: Account to receive the NFT
     * @param id: Identification of the NFT to be delivered (NFT ID could be reserved or not)
     */
    function safeMint(address to, uint256 id) public onlyRole(MINTER_ROLE) {
        deliverNftById(to, id);
    }

    /**
     * @dev This function increments the counter when the ID is either reserved or has an owner
     * @dev Delivers the NFT when it finds an ID that is not reserved and without owner
     * @param to: Account to receive the NFT
     */
    function deliverNft(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        while (_exists(tokenId) || reservedNft[tokenId]) {
            _tokenIdCounter.increment();
            tokenId = _tokenIdCounter.current();
        }

        if (tokenId >= maxSupply) {
            revert(
                "Pachachuy NFT Collection: the ID count has reached its maximun supply."
            );
        }

        _safeMint(to, tokenId);
    }

    /**
     * @dev This function delivers an NFT by using its ID
     * @param to: Account to receive the NFT
     * @param id: NFT's ID. That ID could be either reserved or not
     */
    function deliverNftById(address to, uint256 id) internal {
        require(
            !_exists(id),
            "Pachacuy NFT Collection: This NFT id has been minted already."
        );

        require(
            id >= 0 && id < maxSupply,
            "Pachacuy NFT Collection: incorrect ID out of bounds."
        );

        _safeMint(to, id);
    }

    function purchaseNftWithBusdAndId(uint256 _id) public nonReentrant {
        // Verify that NFT id do not have an owner
        require(
            !_exists(_id),
            "Pachacuy NFT Collection: This NFT id has been minted already."
        );

        // Verify that NFT id is not a reserved one
        require(
            !reservedNft[_id],
            "Pachacuy NFT Collection: You cannot mint a Reserved NFT ID."
        );

        // Customer needs to give allowance to Smart Contract

        // Verify if customer has BUSDC balance
        require(
            busdToken.balanceOf(_msgSender()) >= nftCurrentPrice,
            "Pachacuy NFT Collection: Not enough BUSD balance."
        );

        // Verify id customer has given allowance to NFT Smart Contract
        require(
            busdToken.allowance(_msgSender(), address(this)) >= nftCurrentPrice,
            "Pachacuy NFT Collection: Allowance has not been given."
        );

        // SC transfers BUSD from purchaser to custodian wallet
        busdToken.safeTransferFrom(
            _msgSender(),
            custodianWallet,
            nftCurrentPrice
        );

        deliverNftById(_msgSender(), _id);
    }

    function purchaseNftWithBusd() public nonReentrant {
        // Customer needs to give allowance to Smart Contract

        // Verify if customer has BUSDC balance
        require(
            busdToken.balanceOf(_msgSender()) >= nftCurrentPrice,
            "Pachacuy NFT Collection: Not enough BUSD balance."
        );

        // Verify id customer has given allowance to NFT Smart Contract
        require(
            busdToken.allowance(_msgSender(), address(this)) >= nftCurrentPrice,
            "Pachacuy NFT Collection: Allowance has not been given."
        );

        // SC transfers BUSD from purchaser to custodian wallet
        busdToken.safeTransferFrom(
            _msgSender(),
            custodianWallet,
            nftCurrentPrice
        );

        deliverNft(_msgSender());
    }

    function claimFreeNftByWhitelist() public nonReentrant {
        require(
            whitelist[_msgSender()].inWhitelist,
            "Pachacuy NFT Collection: Account is not in whitelist."
        );

        require(
            !whitelist[_msgSender()].claimed,
            "Pachacuy NFT Collection: Whitelist account already claimed one NFT."
        );

        whitelist[_msgSender()].claimed = true;

        deliverNft(_msgSender());
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function setNftCurrentPrice(uint256 _newNftCurrentPrice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftCurrentPrice = _newNftCurrentPrice;
    }

    function addToWhitelistBatch(address[] memory _addresses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        for (uint256 iy = 0; iy < _addresses.length; iy++) {
            if (!whitelist[_addresses[iy]].inWhitelist) {
                whitelist[_addresses[iy]] = Whitelister({
                    account: _addresses[iy],
                    claimed: false,
                    inWhitelist: true
                });
            }
        }
    }

    function addReservedNftIdsBatch(uint256[] memory _ids)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            if (id >= 0 && id < maxSupply && !reservedNft[id]) {
                reservedNft[id] = true;
                listOfReservedNft.push(id);
            }
        }
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    ///////////////////////////////////////////////////////////////
    ////                ERC721 STANDARD FUNCTIONS              ////
    ///////////////////////////////////////////////////////////////
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
