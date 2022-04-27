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
////                                             MARKETPLACE PACHACUY                                            ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./IERC721ERC1155.sol";

/**
 * 1. from a particular user, we need to find all NFT related to his account (might be done only with libraries)
 * 2. a user needs to be able to approve the sc to manage his NFTs. Also the price could be set up
    - verify that user is the owner
   3. all users are able to see all listed nfts. 
   4. whenever a user is not the owner of the nft anymore, it needs to be updated accordingly in the marketplace SC
 */

/// @custom:security-contact lee@cuytoken.com
contract MarketplacePachacuy is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    // BUSD token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public busdToken;

    // Exchange rate PCUY -> BUSD
    // Means 1 BUSD = 25 PCUY
    uint256 public rateBusdToPcuy;

    // custodian wallet for busd
    address public custodianWallet;

    // ERC721 MocheCollection
    address erc721Address;

    // ERC1155 NFT game elements
    address erc1155Address;

    // PCUY token
    IERC777Upgradeable pachaCuyToken;

    // Generic contract for 721 and 1155
    IERC721ERC1155 nftContract;

    struct NftItem {
        address nftOwner;
        address smartContract;
        uint256 uuid;
        uint256 price; // in PCUY
        bool listed;
    }

    // smart contract address => uuid => NftItem[]
    mapping(address => mapping(uint256 => NftItem)) mapAdressToNftListed;

    // Array of all NftItem listed
    NftItem[] listOfNftItemsToSell;
    // smart contract address => uuid => array index
    mapping(address => mapping(uint256 => uint256)) _nftIx;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _custodianWallet, address _busdAddress)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        busdToken = IERC20Upgradeable(_busdAddress);
        custodianWallet = _custodianWallet;
        rateBusdToPcuy = 25;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function purchaseNftWithBusd(address _smartContractAddress, uint256 _uuid)
        external
        nonReentrant
    {
        _purchaseNft(_smartContractAddress, _uuid, address(busdToken));
    }

    function purchaseNftWithPcuy(address _smartContractAddress, uint256 _uuid)
        external
        nonReentrant
    {
        _purchaseNft(_smartContractAddress, _uuid, address(pachaCuyToken));
    }

    function _purchaseNft(
        address _smartContractAddress,
        uint256 _uuid,
        address _tokenAddress
    ) internal {
        NftItem memory nftItem = mapAdressToNftListed[_smartContractAddress][
            _uuid
        ];
        // verify that nft is listed
        require(nftItem.listed, "Marketplace: NFT is already listed");

        // verify you have given permission
        require(
            isMarketPlaceAllowed(_smartContractAddress, nftItem.nftOwner),
            "Marketplace: Permission was not give to Marketplace SC"
        );

        // Verify if owner of NFT is still the same who listed it
        if (_smartContractAddress == erc721Address) {
            require(
                nftItem.nftOwner ==
                    IERC721ERC1155(_smartContractAddress).ownerOf(_uuid),
                "Marketplace: (721) the NFT's UUID points to a different owner"
            );
        } else if (_smartContractAddress == erc1155Address) {
            require(
                IERC721ERC1155(_smartContractAddress).balanceOf(
                    nftItem.nftOwner,
                    _uuid
                ) > 0,
                "Marketplace: (1155) the NFT's UUID points to a different owner"
            );
        } else {
            revert("Marketplace: SC address passed incorrect");
        }

        // delete mapping
        delete mapAdressToNftListed[_smartContractAddress][_uuid];

        // Make the payment
        _purchaseAtPriceInPcuyAndToken(nftItem.price, _tokenAddress);

        // Make the transfer
        if (_smartContractAddress == erc721Address) {
            IERC721ERC1155(_smartContractAddress).safeTransferFrom(
                nftItem.nftOwner,
                _msgSender(),
                _uuid
            );
        } else if (_smartContractAddress == erc1155Address) {
            IERC721ERC1155(_smartContractAddress).safeTransferFrom(
                nftItem.nftOwner,
                _msgSender(),
                _uuid,
                1,
                ""
            );
        }

        if (listOfNftItemsToSell.length == 1) {
            delete listOfNftItemsToSell[0];

            // decrease counter since array decreased in one
            _tokenIdCounter.decrement();
            return;
        }

        // get _ix of element to remove
        uint256 _ix = _nftIx[_smartContractAddress][_uuid];

        // last index element at last ix of array
        uint256 _lastEl = listOfNftItemsToSell.length - 1;

        // smart contract and uuid do not point anywhere
        delete _nftIx[_smartContractAddress][_uuid];

        // temp of El at last position of array to be removed
        NftItem memory tempNftItem = listOfNftItemsToSell[_lastEl];

        // point last El to index to be replaced
        _nftIx[tempNftItem.smartContract][tempNftItem.uuid] = _ix;

        // swap last El from last position to index to be replaced
        listOfNftItemsToSell[_ix] = listOfNftItemsToSell[_lastEl];

        // remove last element
        listOfNftItemsToSell.pop();

        // decrease counter since array decreased in one
        _tokenIdCounter.decrement();
    }

    function setPriceAndListAsset(
        address _smartContractAddress,
        uint256 _uuid,
        uint256 _price
    ) external {
        // verify that nft is not listed already
        require(
            !mapAdressToNftListed[_smartContractAddress][_uuid].listed,
            "Marketplace: NFT is already listed"
        );

        // verify you have given permission
        require(
            isMarketPlaceAllowed(_smartContractAddress, _msgSender()),
            "Marketplace: Permission was not give to Marketplace SC"
        );

        // verify caller is owner of that NFT
        if (_smartContractAddress == erc721Address) {
            require(
                _msgSender() ==
                    IERC721ERC1155(_smartContractAddress).ownerOf(_uuid),
                "Marketplace: (721) Caller is not the owner of this UUID"
            );
        } else if (_smartContractAddress == erc1155Address) {
            require(
                IERC721ERC1155(_smartContractAddress).balanceOf(
                    _msgSender(),
                    _uuid
                ) > 0,
                "Marketplace: (1155) Caller is not the owner of this UUID"
            );
        } else {
            revert("Marketplace: SC address passed incorrect");
        }

        // List NFT in a mapping
        NftItem memory itemNft = NftItem({
            nftOwner: _msgSender(),
            smartContract: _smartContractAddress,
            uuid: _uuid,
            price: _price,
            listed: true
        });
        mapAdressToNftListed[_smartContractAddress][_uuid] = itemNft;

        listOfNftItemsToSell.push(itemNft);

        uint256 current = _tokenIdCounter.current();
        _nftIx[_smartContractAddress][_uuid] = current;
        _tokenIdCounter.increment();
    }

    function isMarketPlaceAllowed(address _scToVerify, address _account)
        public
        view
        returns (bool)
    {
        return
            IERC721ERC1155(_scToVerify).isApprovedForAll(
                _account,
                address(this)
            );
    }

    function changePriceOfNft(
        address _smartContractAddress,
        uint256 _uuid,
        uint256 _newPrice
    ) external {
        NftItem memory nftItem = mapAdressToNftListed[_smartContractAddress][
            _uuid
        ];

        require(
            nftItem.nftOwner == _msgSender(),
            "Marketplace: Not the NFT owner"
        );

        require(nftItem.listed, "Marketplace: Nft is not listed");

        mapAdressToNftListed[_smartContractAddress][_uuid].price = _newPrice;
    }

    ///////////////////////////////////////////////////////////////
    ////                    HELPER FUNCTIONS                   ////
    ///////////////////////////////////////////////////////////////

    function setPachacuyTokenAddress(address _pachaCuyTokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken = IERC777Upgradeable(_pachaCuyTokenAddress);
    }

    function _fromPcuyToBusd(uint256 _amount) internal view returns (uint256) {
        return _amount / rateBusdToPcuy;
    }

    function _fromBusdToPcuy(uint256 _amount) internal view returns (uint256) {
        return _amount * rateBusdToPcuy;
    }

    function setRateBusdToPcuy(uint256 _newRate)
        external
        onlyRole(GAME_MANAGER)
    {
        require(_newRate > 0, "PurchaseAC: Must be greater than 0");

        rateBusdToPcuy = _newRate;
    }

    function _purchaseAtPriceInPcuyAndToken(
        uint256 _priceInPcuy,
        address _tokenAddress
    ) internal {
        if (_tokenAddress == address(pachaCuyToken)) {
            require(
                pachaCuyToken.balanceOf(_msgSender()) >= _priceInPcuy,
                "Marketplace: Not enough PCUY balance."
            );
            pachaCuyToken.operatorSend(
                _msgSender(),
                custodianWallet,
                _priceInPcuy,
                "",
                ""
            );
        } else if (_tokenAddress == address(busdToken)) {
            _priceInPcuy = _fromPcuyToBusd(_priceInPcuy);
            require(
                busdToken.balanceOf(_msgSender()) >= _priceInPcuy,
                "Marketplace: Not enough BUSD balance."
            );

            // Verify id customer has given allowance to the Marketplace contract
            require(
                busdToken.allowance(_msgSender(), address(this)) >=
                    _priceInPcuy,
                "Marketplace: Allowance has not been given."
            );

            // SC transfers BUSD from purchaser to custodian wallet
            busdToken.safeTransferFrom(
                _msgSender(),
                custodianWallet,
                _priceInPcuy
            );
        }
    }

    function getListOfNftsForSale() external view returns (NftItem[] memory) {
        return listOfNftItemsToSell;
    }

    ///////////////////////////////////////////////////////////////
    ////                 STANDARD SC FUNCTIONS                 ////
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
