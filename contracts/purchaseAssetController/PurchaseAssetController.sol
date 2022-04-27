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
////                                           Purchase Asset Controller                                         ////
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
import "../vrf/IRandomNumberGenerator.sol";
import "../NftProducerPachacuy/INftProducerPachacuy.sol";

/// @custom:security-contact lee@cuytoken.com
contract PurchaseAssetController is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");
    bytes32 public constant RNG_GENERATOR = keccak256("RNG_GENERATOR");

    // BUSD token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public busdToken;

    // PCUY token
    IERC777Upgradeable pachaCuyToken;

    // Exchange rate PCUY -> BUSD
    // Means 1 BUSD = 25 PCUY
    uint256 public rateBusdToPcuy;

    IRandomNumberGenerator public randomNumberGenerator;

    // GuineaPig ERC1155
    INftProducerPachacuy public nftProducerPachacuy;

    // custodian wallet for busd
    address public custodianWallet;

    // price of each pacha
    uint256 public landPrice;

    // Verifies that customer has one transaction at a time
    /**
     * @dev Transaction objects that indicates type of the current transaction
     * @param transactionType - Type of the current transaction: PURCHASE_GUINEA_PIG
     * @param account - The wallet address caller of the customer
     * @param ongoing - Indicates whether the customer has an ongoing transaction
     * @param ix - Indicates the price range (1, 2 or 3) of the current transaction
     */
    struct Transaction {
        string transactionType;
        address account;
        bool ongoing;
        uint256 ix;
    }
    mapping(address => Transaction) ongoingTransaction;

    // likelihood
    struct LikelihoodData {
        uint256 price;
        uint256[] likelihood;
    }
    mapping(uint256 => LikelihoodData) likelihoodData;

    // Marks the beginning of a guinea pig purchase
    event GuineaPigPurchaseFinish(
        address _account,
        uint256 price,
        uint256 _guineaPigId,
        uint256 _uuid,
        string _raceAndGender
    );

    // Marks the end of a guinea pig purchase
    event GuineaPigPurchaseInit(
        address _account,
        uint256 price,
        uint256 _ix,
        address custodianWallet
    );

    // Purchase of Land event
    event PurchaseLand(
        address _account,
        uint256 uuid,
        uint256 landPrice,
        uint256 _location,
        address custodianWallet
    );

    // Purhcase of PachaPass event
    event PurchasePachaPass(
        address _account,
        uint256 uuid,
        uint256 landUuid,
        uint256 price,
        address tokenAddress,
        address custodianWallet
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _randomNumberGeneratorAddress,
        address _custodianWallet,
        address _busdAddress
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        randomNumberGenerator = IRandomNumberGenerator(
            _randomNumberGeneratorAddress
        );

        busdToken = IERC20Upgradeable(_busdAddress);
        custodianWallet = _custodianWallet;

        rateBusdToPcuy = 25;
        landPrice = 200 * rateBusdToPcuy * 1e18;

        // Guniea pig purchase - likelihood
        _setLikelihoodAndPrices(rateBusdToPcuy);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(GAME_MANAGER, _msgSender());
    }

    function fulfillRandomness(
        address _account,
        uint256[] memory _randomNumbers
    ) external onlyRole(RNG_GENERATOR) {
        Transaction memory _tx = ongoingTransaction[_account];

        if (_compareStrings(_tx.transactionType, "PURCHASE_GUINEA_PIG")) {
            _finishPurchaseGuineaPig(
                _tx.ix,
                _account,
                _randomNumbers[0],
                _randomNumbers[1]
            );
            delete ongoingTransaction[_account];
            return;
        }
    }

    function purchaseGuineaPigWithBusd(uint256 _ix) external {
        _purchaseGuineaPig(_ix, address(busdToken));
    }

    function purchaseGuineaPigWithPcuy(uint256 _ix) external {
        _purchaseGuineaPig(_ix, address(pachaCuyToken));
    }

    /**
     * @dev Buy a guinea pig by using an index (_ix represents a specific prive of three)
     * @param _ix Index of the price. There are three prices: 1, 2 and 3
     * @param _tokenAddress Address of the token to use for the purchase (BUSD or PCUY)
     */
    function _purchaseGuineaPig(uint256 _ix, address _tokenAddress) internal {
        // Valid index (1, 2 or 3)
        require(
            _ix == 1 || _ix == 2 || _ix == 3,
            "PurchaseAC: Index must be 1, 2 or 3"
        );

        // Verify that customer does not have an ongoing transaction
        require(
            !ongoingTransaction[_msgSender()].ongoing,
            "PurchaseAC: Customer cannot have multiple ongoing transactions."
        );

        uint256 price = likelihoodData[_ix].price;

        // Make transfer with appropiate token address
        _purchaseAtPriceInPcuyAndToken(price, _tokenAddress);

        // Mark as ongoing transaction for a customer
        ongoingTransaction[_msgSender()] = Transaction({
            transactionType: "PURCHASE_GUINEA_PIG",
            account: _msgSender(),
            ongoing: true,
            ix: _ix
        });

        // Ask for two random numbers
        randomNumberGenerator.requestRandomNumber(_msgSender(), 2);

        // Emit event
        emit GuineaPigPurchaseInit(_msgSender(), price, _ix, custodianWallet);
    }

    function purchaseLandWithBusd(uint256 _location) external {
        _purchaseLand(_location, address(busdToken));
    }

    function purchaseLandWithPcuy(uint256 _location) external {
        _purchaseLand(_location, address(pachaCuyToken));
    }

    /**
     * @dev Buy a guinea pig by using an index (_ix represents a specific prive of three)
     * @param _location Location of the land from 1 to 697
     */
    function _purchaseLand(uint256 _location, address _tokenAddress) internal {
        // Make transfer with appropiate token address
        _purchaseAtPriceInPcuyAndToken(landPrice, _tokenAddress);

        // mint a pacha
        uint256 uuid = nftProducerPachacuy.mintLandNft(
            _msgSender(),
            _location,
            ""
        );

        // Emit event
        emit PurchaseLand(
            _msgSender(),
            uuid,
            landPrice,
            _location,
            custodianWallet
        );
    }

    function _purchaseAtPriceInPcuyAndToken(
        uint256 _priceInPcuy,
        address _tokenAddress
    ) internal {
        if (_tokenAddress == address(pachaCuyToken)) {
            require(
                pachaCuyToken.balanceOf(_msgSender()) >= _priceInPcuy,
                "PurchaseAC: Not enough PCUY balance."
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
                "PurchaseAC: Not enough BUSD balance."
            );

            // Verify id customer has given allowance to the PurchaseAC contract
            require(
                busdToken.allowance(_msgSender(), address(this)) >=
                    _priceInPcuy,
                "PurchaseAC: Allowance has not been given."
            );

            // SC transfers BUSD from purchaser to custodian wallet
            busdToken.safeTransferFrom(
                _msgSender(),
                custodianWallet,
                _priceInPcuy
            );
        }
    }

    function purchasePachaPassWithPcuy(uint256 _landUuid)
        external
        returns (uint256)
    {
        return _purchasePachaPass(_landUuid, address(pachaCuyToken));
    }

    function purchasePachaPassWithBusd(uint256 _landUuid)
        external
        returns (uint256)
    {
        return _purchasePachaPass(_landUuid, address(busdToken));
    }

    /**
     * @notice Buy a Pacha Pass for a land that exist. It's purchase with PCUY only
     * @notice To sell a Pacha Pass, a land must have been converted to private first
     * @notice Type of distribution must be 2 for the Land
     * @param _landUuid an existant uuid for the land whose PachaPass will be minted
     * @param _tokenAddress token address to use for the purchase
     */
    function _purchasePachaPass(uint256 _landUuid, address _tokenAddress)
        internal
        returns (uint256)
    {
        (
            ,
            bool isPublic,
            ,
            uint256 pachaPassUuid,
            uint256 pachaPassPrice,
            uint256 typeOfDistribution,
            ,
            ,
            ,
            address owner
        ) = nftProducerPachacuy.getLandData(_landUuid);

        require(!isPublic, "PurchaseAC: Land must be private");
        require(pachaPassUuid > 0, "PurchaseAC: PachaPass uuid does not exist");
        require(typeOfDistribution == 2, "PurchaseAC: Distribution non-public");
        require(pachaPassPrice > 0, "PurchaseAC: Price must be greater than 0");

        // Fee is calculated in PCUY only. 'pachaPassPrice' is in PCUY
        uint256 _fee = (pachaPassPrice * 18) / 100;
        uint256 _net = pachaPassPrice - _fee;

        // Purchase with PCUY
        if (_tokenAddress == address(pachaCuyToken)) {
            require(
                pachaCuyToken.balanceOf(_msgSender()) >= pachaPassPrice,
                "PurchaseAC: Not enough PCUY balance"
            );

            // No need to verify allowance

            // SC transfers PCUY from purchaser to custodian wallet
            pachaCuyToken.operatorSend(
                _msgSender(),
                custodianWallet,
                _fee,
                "",
                ""
            );

            // SC transfers PCUY from purchaser to pacha owner
            pachaCuyToken.operatorSend(_msgSender(), owner, _net, "", "");
        } else if (_tokenAddress == address(busdToken)) {
            pachaPassPrice = _fromPcuyToBusd(pachaPassPrice);
            _fee = _fromPcuyToBusd(_fee);
            _net = _fromPcuyToBusd(_net);

            require(
                busdToken.balanceOf(_msgSender()) >= pachaPassPrice,
                "PurchaseAC: Not enough BUSD balance"
            );

            // Verify that customer has given allowance to the PurchaseAC contract
            require(
                busdToken.allowance(_msgSender(), address(this)) >=
                    pachaPassPrice,
                "PurchaseAC: Allowance has not been given"
            );

            // SC transfers BUSD from purchaser to custodian wallet
            busdToken.safeTransferFrom(_msgSender(), custodianWallet, _fee);

            // SC transfers BUSD from purchaser to pacha owner
            busdToken.safeTransferFrom(_msgSender(), owner, _net);
        } else {
            revert("PurchaseAC: Token address invalid");
        }

        // Mint a pachapass
        nftProducerPachacuy.mintPachaPassNft(
            _msgSender(),
            _landUuid,
            pachaPassUuid,
            typeOfDistribution,
            pachaPassPrice,
            "purchased"
        );

        // Emit event
        emit PurchasePachaPass(
            _msgSender(),
            pachaPassUuid,
            _landUuid,
            pachaPassPrice,
            _tokenAddress,
            custodianWallet
        );

        return pachaPassUuid;
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

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
        _setLikelihoodAndPrices(_newRate);
    }

    function _finishPurchaseGuineaPig(
        uint256 _ix,
        address _account,
        uint256 _randomNumber1,
        uint256 _randomNumber2
    ) internal {
        (
            uint256 _gender,
            uint256 _race,
            uint256 _guineaPigId, // idForJsonFile 1 -> 8
            string memory _raceAndGender
        ) = _getRaceGenderGuineaPig(
                _ix,
                (_randomNumber1 % 100) + 1,
                _randomNumber2 % 2
            );

        // Mark ongoing transaction as finished
        ongoingTransaction[_account].ongoing = false;

        require(
            address(nftProducerPachacuy) != address(0),
            "PurchaseAC: Guinea Pig Token not set."
        );

        // Mint Guinea Pigs
        uint256 _uuid = nftProducerPachacuy.mintGuineaPigNft(
            _account,
            _gender,
            _race,
            _guineaPigId,
            ""
        );

        emit GuineaPigPurchaseFinish(
            _account,
            likelihoodData[_ix].price,
            _guineaPigId,
            _uuid,
            _raceAndGender
        );
    }

    function _setLikelihoodAndPrices(uint256 _rateBusdToPcuy) internal {
        likelihoodData[1] = LikelihoodData(
            5 * _rateBusdToPcuy * 1e18,
            new uint256[](4)
        );
        likelihoodData[1].likelihood = [70, 85, 95, 100];

        likelihoodData[2] = LikelihoodData(
            10 * _rateBusdToPcuy * 1e18,
            new uint256[](4)
        );
        likelihoodData[2].likelihood = [20, 50, 80, 100];

        likelihoodData[3] = LikelihoodData(
            15 * _rateBusdToPcuy * 1e18,
            new uint256[](4)
        );
        likelihoodData[3].likelihood = [10, 30, 60, 100];
    }

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
    function _getRaceGenderGuineaPig(
        uint256 _ix,
        uint256 _raceRN, // [1, 100]
        uint256 _genderRN // [0, 1]
    )
        internal
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
        for (i = 0; i < likelihoodData[_ix].likelihood.length; i++) {
            if (_raceRN <= likelihoodData[_ix].likelihood[i]) break;
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

    function _compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function setRandomNumberGeneratorAddress(
        address _randomNumberGeneratorAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        randomNumberGenerator = IRandomNumberGenerator(
            _randomNumberGeneratorAddress
        );
    }

    function setNftProducerPachacuyAddress(address _NftProducerPachacuy)
        public
        onlyRole(GAME_MANAGER)
    {
        nftProducerPachacuy = INftProducerPachacuy(_NftProducerPachacuy);
    }

    function resetOngoingTransactionForAccount(address _account)
        public
        onlyRole(GAME_MANAGER)
    {
        if (ongoingTransaction[_account].ongoing) {
            ongoingTransaction[_account].ongoing = false;
        }
    }

    function getTransactionData(address _account)
        external
        view
        returns (
            string memory transactionType,
            address account,
            bool ongoing,
            uint256 ix
        )
    {
        transactionType = ongoingTransaction[_account].transactionType;
        account = ongoingTransaction[_account].account;
        ongoing = ongoingTransaction[_account].ongoing;
        ix = ongoingTransaction[_account].ix;
    }

    function setLandPrice(uint256 _landPrice) external onlyRole(GAME_MANAGER) {
        landPrice = _landPrice;
    }

    function setPachacuyTokenAddress(address _pachaCuyTokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken = IERC777Upgradeable(_pachaCuyTokenAddress);
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
