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
import "../chakra/IChakra.sol";
import "../pacha/IPacha.sol";
import "../info/IPachacuyInfo.sol";
import "../misayWasi/IMisayWasi.sol";
import "../guineapig/IGuineaPig.sol";

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
    bytes32 public constant MONEY_TRANSFER = keccak256("MONEY_TRANSFER");

    using StringsUpgradeable for uint256;

    // BUSD token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public busdToken;

    // PCUY token
    IERC777Upgradeable pachaCuyToken;

    // chakra
    IChakra chakra;

    // Pachacuy Information
    IPachacuyInfo pachacuyInfo;

    IRandomNumberGenerator public randomNumberGenerator;

    // GuineaPig ERC1155
    INftProducerPachacuy public nftProducerPachacuy;

    // pool rewards for busd
    address public poolRewardsAddress;

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

    // Marks the end of a guinea pig purchase
    event GuineaPigPurchaseFinish(
        address _account,
        uint256 price,
        uint256 _guineaPigId,
        uint256 _uuid,
        string _raceAndGender
    );

    // Marks the beginning of a guinea pig purchase
    event GuineaPigPurchaseInit(
        address _account,
        uint256 price,
        uint256 _ix,
        address poolRewardsAddress
    );

    // Purchase of Land event
    event PurchaseLand(
        address _account,
        uint256 uuid,
        uint256 landPrice,
        uint256 _location,
        address poolRewardsAddress
    );

    // Purhcase of PachaPass event
    event PurchasePachaPass(
        address account,
        uint256 pachaUuid,
        uint256 pachaPassUuid,
        uint256 price,
        uint256 pcuyReceived,
        uint256 pcuyTaxed
    );

    event PurchaseFoodChakra(
        uint256 chakraUuid,
        uint256 amountOfFood,
        uint256 availableFood,
        address chakraOwner,
        uint256 pcuyReceived,
        uint256 pcuyTaxed,
        uint256 tax
    );

    event Testing(
        uint256 _gender,
        uint256 _race,
        uint256 _guineaPigId,
        string _raceAndGender
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _randomNumberGeneratorAddress,
        address _poolRewardsAddress,
        address _busdAddress
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        randomNumberGenerator = IRandomNumberGenerator(
            _randomNumberGeneratorAddress
        );

        busdToken = IERC20Upgradeable(_busdAddress);
        poolRewardsAddress = _poolRewardsAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(GAME_MANAGER, _msgSender());
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
            "PurchaseAC: Multiple ongoing transactions"
        );

        uint256 price = pachacuyInfo.getPriceInPcuy(
            abi.encodePacked("GUINEA_PIG_", _ix.toString())
        ) * 10**18;

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
        emit GuineaPigPurchaseInit(
            _msgSender(),
            price,
            _ix,
            poolRewardsAddress
        );
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
        uint256 pachaPrice = pachacuyInfo.getPriceInPcuy("PACHA") * 10**18;

        // Make transfer with appropiate token address
        _purchaseAtPriceInPcuyAndToken(pachaPrice, _tokenAddress);

        // mint a pacha
        uint256 uuid = nftProducerPachacuy.mintLandNft(
            _msgSender(),
            _location,
            pachaPrice,
            ""
        );

        // Emit event
        emit PurchaseLand(
            _msgSender(),
            uuid,
            pachaPrice,
            _location,
            poolRewardsAddress
        );
    }

    function _purchaseAtPriceInPcuyAndToken(
        uint256 _priceInPcuy,
        address _tokenAddress
    ) internal {
        if (_tokenAddress == address(pachaCuyToken)) {
            require(
                pachaCuyToken.balanceOf(_msgSender()) >= _priceInPcuy,
                "PAC: Not enough PCUY"
            );
            pachaCuyToken.operatorSend(
                _msgSender(),
                poolRewardsAddress,
                _priceInPcuy,
                "",
                ""
            );
        } else if (_tokenAddress == address(busdToken)) {
            _priceInPcuy = _fromPcuyToBusd(_priceInPcuy);
            require(
                busdToken.balanceOf(_msgSender()) >= _priceInPcuy,
                "PAC: Not enough BUSD"
            );

            // Verify id customer has given allowance to the PurchaseAC contract
            require(
                busdToken.allowance(_msgSender(), address(this)) >=
                    _priceInPcuy,
                "PAC: Allowance not given"
            );

            // SC transfers BUSD from purchaser to pool rewards
            busdToken.safeTransferFrom(
                _msgSender(),
                poolRewardsAddress,
                _priceInPcuy
            );
        }
    }

    function purchaseChakra(uint256 _pachaUuid)
        external
        returns (uint256 chakraUuid)
    {
        uint256 _chakraPrice = pachacuyInfo.getPriceInPcuy("CHAKRA") * 10**18;
        _purchaseAtPriceInPcuyAndToken(_chakraPrice, address(pachaCuyToken));

        // mint a chakra
        chakraUuid = nftProducerPachacuy.mintChakra(
            _msgSender(),
            _pachaUuid,
            _chakraPrice
        );
    }

    /**
     * @notice Purchase a specific amount of food at a chakra by using its uuid
     * @param _chakraUuid: uuid of the chakra from where food is being purchased
     * @param _amountFood: amount of food to be purchased from chakra
     * @param _guineaPigUuid: uuid of the guinea pig being fed
     */
    function purchaseFoodFromChakra(
        uint256 _chakraUuid,
        uint256 _amountFood,
        uint256 _guineaPigUuid
    ) external {
        IChakra.ChakraInfo memory chakraInfo = IChakra(
            pachacuyInfo.chakraAddress()
        ).getChakraWithUuid(_chakraUuid);

        require(chakraInfo.hasChakra, "PAC: Chakra not found");

        require(
            _amountFood <= chakraInfo.availableFood,
            "PAC: Not enough food at chakra"
        );

        (uint256 _net, uint256 _fee) = _transferPcuyWithTax(
            _msgSender(),
            chakraInfo.owner,
            chakraInfo.pricePerFood * _amountFood
        );

        uint256 availableFood = nftProducerPachacuy.purchaseFood(
            _msgSender(),
            _chakraUuid,
            _amountFood,
            _guineaPigUuid
        );

        emit PurchaseFoodChakra(
            _chakraUuid,
            _amountFood,
            availableFood,
            chakraInfo.owner,
            _net,
            _fee,
            pachacuyInfo.purchaseTax()
        );
    }

    /**
     * @notice Purchase a specific amount of food at a chakra by using its uuid
     * @param _misayWasiUuid: uuid of the misay wasi where the tickets are being purchased
     * @param _amountOfTickets: amount of food to be purchased from chakra
     */
    function purchaseTicketFromMisayWasi(
        uint256 _misayWasiUuid,
        uint256 _amountOfTickets
    ) external {
        IMisayWasi.MisayWasiInfo memory misayWasiInfo = IMisayWasi(
            pachacuyInfo.misayWasiAddress()
        ).getMisayWasiWithUuid(_misayWasiUuid);

        require(misayWasiInfo.isCampaignActive, "PAC: No raffle running");
        _transferPcuyWithoutTax(
            _msgSender(),
            misayWasiInfo.owner,
            misayWasiInfo.ticketPrice * _amountOfTickets
        );

        nftProducerPachacuy.purchaseTicketRaffle(
            _msgSender(),
            misayWasiInfo.ticketUuid,
            _misayWasiUuid,
            _amountOfTickets
        );
    }

    function purchaseMisayWasi(uint256 _pachaUuid) external {
        uint256 _misayWasiPrice = pachacuyInfo.getPriceInPcuy("MISAY_WASI") *
            10**18;
        _purchaseAtPriceInPcuyAndToken(_misayWasiPrice, address(pachaCuyToken));
        // mint a Misay Wasi
        nftProducerPachacuy.mintMisayWasi(
            _msgSender(),
            _pachaUuid,
            _misayWasiPrice
        );
    }

    function purchaseQhatuWasi(uint256 _pachaUuid) external {
        uint256 _qhatuWasiPrice = pachacuyInfo.getPriceInPcuy("QHATU_WASI") *
            10**18;
        _purchaseAtPriceInPcuyAndToken(_qhatuWasiPrice, address(pachaCuyToken));

        // mint a Qhatu Wasi
        nftProducerPachacuy.mintQhatuWasi(
            _pachaUuid,
            _msgSender(),
            _qhatuWasiPrice
        );
    }

    function purchasePachaPass(uint256 _pachaUuid) external {
        IPacha.PachaInfo memory pacha = IPacha(pachacuyInfo.pachaAddress())
            .getPachaWithUuid(_pachaUuid);

        // pacha exists
        require(pacha.isPacha, "PAC: do not exist");

        // pacha is private
        require(!pacha.isPublic, "PAC: not public");

        // typeOfDistribution = 1 => price = 0
        // typeOfDistribution = 2 => price > 0
        require(pacha.typeOfDistribution == 2, "PAC: not for purchase");

        // Pacha pass exists
        require(pacha.pachaPassUuid > 0, "NFP: PachaPass do not exist");

        // mint NFT
        nftProducerPachacuy.mintPachaPass(
            _msgSender(),
            pacha.uuid,
            pacha.pachaPassUuid
        );

        // puchase
        (uint256 _net, uint256 _fee) = _transferPcuyWithTax(
            _msgSender(),
            pacha.owner,
            pacha.pachaPassPrice
        );

        emit PurchasePachaPass(
            _msgSender(),
            pacha.uuid,
            pacha.pachaPassUuid,
            pacha.pachaPassPrice,
            _net,
            _fee
        );
    }

    function transferPcuyFromUserToPoolReward(
        address _account,
        uint256 _pcuyAmount
    ) external onlyRole(MONEY_TRANSFER) {
        require(
            pachaCuyToken.balanceOf(_account) >= _pcuyAmount,
            "PAC: Not enough PCUY"
        );

        pachaCuyToken.operatorSend(
            _account,
            poolRewardsAddress,
            _pcuyAmount,
            "",
            ""
        );
    }

    function transferPcuyFromPoolRewardToUser(
        address _account,
        uint256 _pcuyAmount
    ) external onlyRole(MONEY_TRANSFER) {
        pachaCuyToken.operatorSend(
            poolRewardsAddress,
            _account,
            _pcuyAmount,
            "",
            ""
        );
    }

    function _transferPcuyWithTax(
        address _from,
        address _to,
        uint256 _pcuyAmount
    ) internal returns (uint256 _net, uint256 _fee) {
        require(
            pachaCuyToken.balanceOf(_from) >= _pcuyAmount,
            "PAC: Not enough PCUY"
        );

        _fee = (_pcuyAmount * pachacuyInfo.purchaseTax()) / 100;
        _net = _pcuyAmount - _fee;

        pachaCuyToken.operatorSend(_from, _to, _net, "", "");
        pachaCuyToken.operatorSend(
            _from,
            pachacuyInfo.poolRewardAddress(),
            _fee,
            "",
            ""
        );
    }

    function _transferPcuyWithoutTax(
        address _from,
        address _to,
        uint256 _pcuyAmount
    ) internal {
        require(
            pachaCuyToken.balanceOf(_from) >= _pcuyAmount,
            "PAC: Not enough PCUY"
        );
        pachaCuyToken.operatorSend(_from, _to, _pcuyAmount, "", "");
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function _fromPcuyToBusd(uint256 _amount) internal returns (uint256) {
        return _amount / pachacuyInfo.exchangeRateBusdToPcuy();
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
        ) = IGuineaPig(pachacuyInfo.guineaPigAddress()).getRaceGenderGuineaPig(
                _ix,
                (_randomNumber1 % 100) + 1,
                _randomNumber2 % 2
            );

        require(
            address(nftProducerPachacuy) != address(0),
            "PAC: Guinea Pig Token not set"
        );

        uint256 price = pachacuyInfo.getPriceInPcuy(
            abi.encodePacked("GUINEA_PIG_", _ix.toString())
        ) * 10**18;

        // Mint Guinea Pigs
        uint256 _uuid = INftProducerPachacuy(pachacuyInfo.nftProducerAddress())
            .mintGuineaPigNft(_account, _gender, _race, _guineaPigId, price);

        emit GuineaPigPurchaseFinish(
            _account,
            price,
            _guineaPigId,
            _uuid,
            _raceAndGender
        );
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

    function setNftPAddress(address _NftProducerPachacuy)
        public
        onlyRole(GAME_MANAGER)
    {
        nftProducerPachacuy = INftProducerPachacuy(_NftProducerPachacuy);
    }

    function setPcuyTokenAddress(address _pachaCuyTokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken = IERC777Upgradeable(_pachaCuyTokenAddress);
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
