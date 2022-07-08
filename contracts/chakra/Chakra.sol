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
////                                                    Chakra                                                   ////
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

/// @custom:security-contact lee@cuytoken.com
contract Chakra is
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

    /**
     * @dev Details the information of a Tatacuy. Additional properties attached for its campaign
     * @param owner: Wallet address of the current owner of the Tatacuy
     * @param chakraUuid: Uuid of the chakra when it was minted
     * @param pachaUuid: Uuid of the pacha where the chakra belongs to
     * @param creationDate: Date when the chakra was minted
     * @param priceOfChakra: Price in PCUY of the chakra NFT
     * @param pricePerFood: Price in PCUY to pay for each food by the Guinea Pig
     * @param totalFood: Number of food to be purchased from chakra
     * @param availableFood: Amount of food available to sell. Decrease one by one as Guinea Pig purchase food
     * @param hasChakra: Indicates wheter a chakra exists or not
     */
    struct ChakraInfo {
        address owner;
        uint256 chakraUuid;
        uint256 pachaUuid;
        uint256 creationDate;
        uint256 priceOfChakra;
        uint256 pricePerFood;
        uint256 totalFood;
        uint256 availableFood;
        bool hasChakra;
    }
    // Chakra UUID  -> Struct of Chakra Info
    mapping(uint256 => ChakraInfo) internal uuidToChakraInfo;

    // List of Available Chakras
    ChakraInfo[] listOfChakrasWithFood;
    // chakra uuid => array index
    mapping(uint256 => uint256) internal _chakraIx;

    event PurchaseChakra(
        address owner,
        uint256 chakraUuid,
        uint256 pachaUuid,
        uint256 chakraPrice,
        uint256 creationDate
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _pachacuyInfoAdd) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        pachacuyInfo = IPachacuyInfo(_pachacuyInfoAdd);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(GAME_MANAGER, _msgSender());
    }

    /**
     * @dev Trigger when it is minted
     * @param _account: Wallet address of the current owner of the Pacha
     * @param _pachaUuid: Uuid of the pacha when it was minted
     * @param _chakraUuid: Uuid of the Tatacuy when it was minted
     * @param _chakraPrice: Price in PCUY of the chakra
     */
    function registerChakra(
        address _account,
        uint256 _pachaUuid,
        uint256 _chakraUuid,
        uint256 _chakraPrice
    ) external onlyRole(GAME_MANAGER) {
        uint256 _totalFood = pachacuyInfo.totalFood();
        uint256 _pricePerFood = pachacuyInfo.pricePerFood();

        ChakraInfo memory chakra = ChakraInfo({
            owner: _account,
            chakraUuid: _chakraUuid,
            pachaUuid: _pachaUuid,
            creationDate: block.timestamp,
            priceOfChakra: _chakraPrice,
            pricePerFood: _pricePerFood,
            totalFood: _totalFood,
            availableFood: _totalFood,
            hasChakra: true
        });
        uuidToChakraInfo[_chakraUuid] = chakra;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _chakraIx[_chakraUuid] = current;
        listOfChakrasWithFood.push(chakra);

        emit PurchaseChakra(
            _account,
            _chakraUuid,
            _pachaUuid,
            _chakraPrice,
            block.timestamp
        );
    }

    function updateFoodPriceAtChakra(uint256 _chakraUuid, uint256 _pricePerFood)
        external
    {
        ChakraInfo storage chakraInfo1 = uuidToChakraInfo[_chakraUuid];
        require(_msgSender() == chakraInfo1.owner, "Chakra: Not the owner");
        chakraInfo1.pricePerFood = _pricePerFood;

        uint256 _ix = _chakraIx[_chakraUuid];
        ChakraInfo storage chakraInfo2 = listOfChakrasWithFood[_ix];
        chakraInfo2.pricePerFood = _pricePerFood;
    }

    function consumeFoodFromChakra(uint256 _chakraUuid, uint256 _amountFood)
        external
        onlyRole(GAME_MANAGER)
        returns (uint256)
    {
        require(_amountFood > 0, "Chakra: Amount food cannot be 0");

        ChakraInfo storage chakra = uuidToChakraInfo[_chakraUuid];

        if (chakra.availableFood >= _amountFood) {
            unchecked {
                chakra.availableFood -= _amountFood;
            }

            if (chakra.availableFood == 0) {
                _removeChakraWithUuid(_chakraUuid);
            }
            return chakra.availableFood;
        }

        revert("Chakra: No food at chakra");
    }

    function burnChakra(uint256 _chakraUuid) external onlyRole(GAME_MANAGER) {
        delete uuidToChakraInfo[_chakraUuid];
        _removeChakraWithUuid(_chakraUuid);
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function _removeChakraWithUuid(uint256 _chakraUuid) internal {
        uint256 _length = listOfChakrasWithFood.length;
        if (_length == 1) {
            listOfChakrasWithFood.pop();
            delete _chakraIx[_chakraUuid];
            _tokenIdCounter.decrement();
        }

        // get _ix of element to remove
        uint256 _ix = _chakraIx[_chakraUuid];
        delete _chakraIx[_chakraUuid];

        // temp of El at last position of array to be removed
        ChakraInfo memory _chakra = listOfChakrasWithFood[_length - 1];

        // point last El to index to be replaced
        _chakraIx[_chakra.chakraUuid] = _ix;

        // swap last El from last position to index to be replaced
        listOfChakrasWithFood[_ix] = _chakra;

        // remove last element
        listOfChakrasWithFood.pop();

        // decrease counter since array decreased in one
        _tokenIdCounter.decrement();
    }

    function tokenUri(uint256 _chakraUuid)
        public
        view
        returns (string memory)
    {}

    function getListOfChakrasWithFood()
        external
        view
        returns (ChakraInfo[] memory)
    {
        return listOfChakrasWithFood;
    }

    function getChakraWithUuid(uint256 _chakraUuid)
        external
        view
        returns (ChakraInfo memory)
    {
        return uuidToChakraInfo[_chakraUuid];
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
