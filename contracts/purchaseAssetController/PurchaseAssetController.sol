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
import "../vrf/IRandomNumberGenerator.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
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

    // PCUY token
    IERC777Upgradeable pachaCuyToken;

    // chakra
    IChakra chakra;

    // Pachacuy Information
    IPachacuyInfo pachacuyInfo;

    // GuineaPig ERC1155
    INftProducerPachacuy public nftProducerPachacuy;

    // pool rewards address
    address public poolRewardsAddress;

    // Random number generator
    IRandomNumberGenerator public randomNumberGenerator;

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
        string _raceAndGender,
        uint256 balanceConsumer
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
        address poolRewardsAddress,
        uint256 balanceConsumer
    );

    // Purhcase of PachaPass event
    event PurchasePachaPass(
        address account,
        address pachaOwner,
        uint256 pachaUuid,
        uint256 pachaPassUuid,
        uint256 price,
        uint256 pcuyReceived,
        uint256 pcuyTaxed,
        uint256 balanceOwner,
        uint256 balanceConsumer
    );

    event PurchaseFoodChakra(
        uint256 chakraUuid,
        uint256 amountOfFood,
        uint256 availableFood,
        address chakraOwner,
        uint256 pcuyReceived,
        uint256 pcuyTaxed,
        uint256 tax,
        uint256 balanceOwner,
        uint256 balanceConsumer
    );

    event PurchaseTicket(
        address misayWasiOwner,
        uint256 misayWasiUuid,
        uint256 ticketUuid,
        uint256 balanceOwner,
        uint256 balanceConsumer
    );

    event ErrorString(string reason);
    event ErrorNotHandled(bytes reason);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _randomNumberGeneratorAddress,
        address _poolRewardsAddress
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        poolRewardsAddress = _poolRewardsAddress;

        randomNumberGenerator = IRandomNumberGenerator(
            _randomNumberGeneratorAddress
        );

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(GAME_MANAGER, _msgSender());
    }

    /**
     * @dev Buy a guinea pig by using an index (_ix represents a specific prive of three)
     * @param _ix Index of the price. There are three prices: 1, 2 and 3
     */
    function purchaseGuineaPigWithPcuy(uint256 _ix) external {
        // Valid index (1, 2 or 3)
        require(
            _ix == 1 || _ix == 2 || _ix == 3,
            "PurchaseAC: Index must be 1, 2 or 3"
        );

        require(
            !ongoingTransaction[_msgSender()].ongoing,
            "PurchaseAC: Multiple ongoing transactions"
        );

        uint256 price = pachacuyInfo.getPriceInPcuy(
            abi.encodePacked("GUINEA_PIG_", _ix.toString())
        ) * 10**18;

        // Make transfer from user to business wallet
        _purchaseAtPriceInPcuy(price);

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

    /**
     * @dev Buy a guinea pig by using an index (_ix represents a specific prive of three)
     * @param _location Location of the land from 1 to 697
     */
    function purchaseLandWithPcuy(uint256 _location) external {
        uint256 pachaPrice = pachacuyInfo.getPriceInPcuy("PACHA") * 10**18;

        // Make transfer with appropiate token address
        _purchaseAtPriceInPcuy(pachaPrice);

        // mint a pacha
        uint256 uuid = INftProducerPachacuy(pachacuyInfo.nftProducerAddress())
            .mint(
                keccak256("PACHA"),
                abi.encode(_msgSender(), _location, pachaPrice),
                _msgSender()
            );

        // Emit event
        emit PurchaseLand(
            _msgSender(),
            uuid,
            pachaPrice,
            _location,
            poolRewardsAddress,
            pachaCuyToken.balanceOf(_msgSender())
        );
    }

    function _purchaseAtPriceInPcuy(uint256 _priceInPcuy) internal {
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
    }

    function purchaseChakra(uint256 _pachaUuid) external {
        uint256 _chakraPrice = pachacuyInfo.getPriceInPcuy("CHAKRA") * 10**18;
        _purchaseAtPriceInPcuy(_chakraPrice);

        // mint a chakra
        INftProducerPachacuy(pachacuyInfo.nftProducerAddress()).mint(
            keccak256("CHAKRA"),
            abi.encode(_msgSender(), _pachaUuid, _chakraPrice),
            _msgSender()
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
            pachacuyInfo.purchaseTax(),
            pachaCuyToken.balanceOf(chakraInfo.owner),
            pachaCuyToken.balanceOf(_msgSender())
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

        emit PurchaseTicket(
            misayWasiInfo.owner,
            _misayWasiUuid,
            misayWasiInfo.ticketUuid,
            pachaCuyToken.balanceOf(misayWasiInfo.owner),
            pachaCuyToken.balanceOf(_msgSender())
        );
    }

    function purchaseMisayWasi(uint256 _pachaUuid) external {
        uint256 _misayWasiPrice = pachacuyInfo.getPriceInPcuy("MISAY_WASI") *
            10**18;

        _purchaseAtPriceInPcuy(_misayWasiPrice);

        // mint a Misay Wasi
        INftProducerPachacuy(pachacuyInfo.nftProducerAddress()).mint(
            keccak256("MISAYWASI"),
            abi.encode(_msgSender(), _pachaUuid, _misayWasiPrice),
            _msgSender()
        );
    }

    function purchaseQhatuWasi(uint256 _pachaUuid) external {
        uint256 _qhatuWasiPrice = pachacuyInfo.getPriceInPcuy("QHATU_WASI") *
            10**18;
        _purchaseAtPriceInPcuy(_qhatuWasiPrice);

        // mint a Qhatu Wasi
        INftProducerPachacuy(pachacuyInfo.nftProducerAddress()).mint(
            keccak256("QHATUWASI"),
            abi.encode(_msgSender(), _pachaUuid, _qhatuWasiPrice),
            _msgSender()
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
            pacha.owner,
            pacha.uuid,
            pacha.pachaPassUuid,
            pacha.pachaPassPrice,
            _net,
            _fee,
            pachaCuyToken.balanceOf(pacha.owner),
            pachaCuyToken.balanceOf(_msgSender())
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
    ) public onlyRole(MONEY_TRANSFER) returns (uint256 _net, uint256 _fee) {
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

    function _finishPurchaseGuineaPig(
        uint256 _ix,
        address _account,
        uint256 _randomNumber1,
        uint256 _randomNumber2
    ) internal {
        uint256 _gender = 1;
        uint256 _race = 3;
        uint256 _guineaPigId = 5; // idForJsonFile 1 -> 8
        string memory _raceAndGender = "PERU FEMALE D";
        try
            IGuineaPig(pachacuyInfo.guineaPigAddress()).getRaceGenderGuineaPig(
                _ix,
                _randomNumber1,
                _randomNumber2
            )
        returns (
            uint256 _g,
            uint256 _r,
            uint256 _gId, // idForJsonFile 1 -> 8
            string memory _ra
        ) {
            _gender = _g;
            _race = _r;
            _guineaPigId = _gId;
            _raceAndGender = _ra;
        } catch Error(string memory reason) {
            emit ErrorString(reason);
        } catch (bytes memory reason) {
            emit ErrorNotHandled(reason);
        }

        require(
            address(nftProducerPachacuy) != address(0),
            "PAC: Guinea Pig Token not set"
        );

        uint256 price = pachacuyInfo.getPriceInPcuy(
            abi.encodePacked("GUINEA_PIG_", _ix.toString())
        ) * 10**18;

        // Mint Guinea Pigs
        uint256 _uuid = 999;
        try
            INftProducerPachacuy(pachacuyInfo.nftProducerAddress()).mint(
                keccak256("GUINEAPIG"),
                abi.encode(_account, _gender, _race, _guineaPigId, price),
                _account
            )
        returns (uint256 _uu) {
            _uuid = _uu;
        } catch Error(string memory reason) {
            emit ErrorString(reason);
        } catch (bytes memory reason) {
            emit ErrorNotHandled(reason);
        }

        uint256 _balance = pachaCuyToken.balanceOf(_account);
        emit GuineaPigPurchaseFinish(
            _account,
            price,
            _guineaPigId,
            _uuid,
            _raceAndGender,
            _balance
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
