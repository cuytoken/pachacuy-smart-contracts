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
////                                            Information API Pachacuy                                         ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract PachacuyInfo is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // NFT types
    bytes32 public constant TATACUY = keccak256("TATACUY");
    bytes32 public constant WIRACOCHA = keccak256("WIRACOCHA");
    bytes32 public constant CHAKRA = keccak256("CHAKRA");
    bytes32 public constant HATUNWASI = keccak256("HATUNWASI");
    bytes32 public constant MISAYWASI = keccak256("MISAYWASI");
    bytes32 public constant QHATUWASI = keccak256("QHATUWASI");
    bytes32 public constant GUINEAPIG = keccak256("GUINEAPIG");
    bytes32 public constant PACHA = keccak256("PACHA");
    bytes32 public constant TICKETRAFFLE = keccak256("TICKETRAFFLE");
    bytes32 public constant PACHAPASS = keccak256("PACHAPASS");

    // Contract addresses
    address public chakraAddress;
    address public poolRewardAddress;
    address public hatunWasiAddress;
    address public wiracochaAddress;
    address public tatacuyAddress;
    address public purchaseACAddress;
    address public pachaCuyTokenAddress;
    address public misayWasiAddress;
    address public nftProducerAddress;
    address public guineaPigAddress;
    address public randomNumberGAddress;
    address public binarySearchAddress;
    address public pachaAddress;
    address public qhatuWasiAddress;

    // Asset Management
    uint256 public purchaseTax;
    uint256 public raffleTax;
    uint256 public qhatuWasiTax;

    // Magical Boxes
    uint256 public amountOfBoxesPerPachaPerDay;
    uint256 public amountOfMinimumSamiPoints;
    uint256 public amountOfMaximumSamiPoints;

    // Rates
    uint256 public exchangeRatePcuyToSami;
    uint256 public exchangeRateBusdToPcuy;

    struct InformationBasedOnRank {
        uint256 maxSamiPoints;
        uint256 boxes;
        uint256 affectation;
    }

    InformationBasedOnRank[] infoArrayBasedOnRank;

    event BoxesPerDayPerPachaDx(uint256 previousAmount, uint256 newAmount);
    event MinimumSamiPointsDx(uint256 previousAmount, uint256 newAmount);
    event MaximumSamiPointsDx(uint256 previousAmount, uint256 newAmount);
    event InfoByRankUpdated(
        uint256 rank,
        uint256 maxSamiPoints,
        uint256 boxes,
        uint256 affectation
    );
    event ExchangeRatePcuyToSamiDx(uint256 previousAmount, uint256 amount);
    event ExchangeRateBusdToPcuyDx(uint256 previousAmount, uint256 amount);

    ///////////////////////////////////////////////////////////////
    ////                        CHAKRA                         ////
    ///////////////////////////////////////////////////////////////
    uint256 public totalFood;
    uint256 public pricePerFood;

    // Prices
    // type of business => price of business
    mapping(bytes32 => uint256) public businesses;

    // Addresses mapping
    mapping(bytes32 => address) public nftTypeToAddress;

    // whitelist
    mapping(address => bool) public whitelist;

    // blacklist
    mapping(address => bool) public blacklist;

    // whitelist with ID
    struct WhiteListS {
        uint256 id;
        address account;
        bool included;
    }
    mapping(uint256 => WhiteListS) public whitelistInfo;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint256[] memory _maxSamiPoints,
        uint256[] memory _boxes,
        uint256[] memory _affectation
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());

        _setInformationBasedOnRank(_maxSamiPoints, _boxes, _affectation);
        _setGameVariables();
    }

    function _setInformationBasedOnRank(
        uint256[] memory _maxSamiPoints,
        uint256[] memory _boxes,
        uint256[] memory _affectation
    ) internal {
        for (uint256 _rank = 0; _rank < _maxSamiPoints.length; _rank++) {
            infoArrayBasedOnRank.push(
                InformationBasedOnRank({
                    maxSamiPoints: _maxSamiPoints[_rank],
                    boxes: _boxes[_rank],
                    affectation: _affectation[_rank]
                })
            );
        }
    }

    function _setGameVariables() internal {
        amountOfBoxesPerPachaPerDay = 300;
        amountOfMinimumSamiPoints = 1;
        amountOfMaximumSamiPoints = 15;

        // 18%
        purchaseTax = 18;
        raffleTax = 18;
        qhatuWasiTax = 8;

        // Food at chakra
        totalFood = 12;
        pricePerFood = 25 * 10**18;

        // rates
        // 1 BUSD = 25 PCUY
        exchangeRateBusdToPcuy = 25;
        // 100 sami points = 1 BUSD
        // 1 BUSD = 25 PCUY
        // 1 PCUY = 4 sami points
        exchangeRatePcuyToSami = 100;
    }

    function setBusinessesPrice(
        uint256[] memory _prices,
        bytes32[] memory _types
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 _ix = 0; _ix < _prices.length; _ix++) {
            businesses[_types[_ix]] = _prices[_ix];
        }
    }

    ///////////////////////////////////////////////////////////////
    ////                     ACCESS LIST                       ////
    ///////////////////////////////////////////////////////////////

    function updateWhitelist(
        address _account,
        bool _included_,
        uint256 _id
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistInfo[_id] = WhiteListS({
            id: _id,
            account: _account,
            included: _included_
        });
        whitelist[_account] = _included_;
    }

    function isWhiteListed(uint256 _id) external view returns (address, bool) {
        return (whitelistInfo[_id].account, whitelistInfo[_id].included);
    }

    function isWhitelistedWithWallet(address _account)
        external
        view
        returns (bool)
    {
        return whitelist[_account];
    }

    function updateBlackList(address _account, bool _included)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        blacklist[_account] = _included;
    }

    function isBlackListed(address _account) external view returns (bool) {
        return blacklist[_account];
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function getPriceInPcuy(bytes memory _type)
        external
        view
        returns (uint256)
    {
        return convertBusdToPcuy(businesses[keccak256(_type)]);
    }

    function setPriceBusinessInBusd(bytes32 _type, uint256 _newPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        businesses[_type] = _newPrice;
    }

    function getAllGameInformation()
        external
        view
        returns (
            InformationBasedOnRank[] memory _infoArrayBasedOnRank,
            uint256 _amountOfBoxesPerPachaPerDay,
            uint256 _amountOfMinimumSamiPoints,
            uint256 _amountOfMaximumSamiPoints,
            uint256 _exchangeRatePcuyToSami
        )
    {
        _infoArrayBasedOnRank = infoArrayBasedOnRank;
        _amountOfBoxesPerPachaPerDay = amountOfBoxesPerPachaPerDay;
        _amountOfMinimumSamiPoints = amountOfMinimumSamiPoints;
        _amountOfMaximumSamiPoints = amountOfMaximumSamiPoints;
        _exchangeRatePcuyToSami = exchangeRatePcuyToSami;
    }

    function getInformationByRank(uint256 _rank)
        external
        view
        returns (InformationBasedOnRank memory)
    {
        return infoArrayBasedOnRank[_rank];
    }

    function updateInformationByRank(
        uint256 _rank,
        uint256 _maxSamiPoints,
        uint256 _boxes,
        uint256 _affectation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        infoArrayBasedOnRank[_rank] = InformationBasedOnRank({
            maxSamiPoints: _maxSamiPoints,
            boxes: _boxes,
            affectation: _affectation
        });

        emit InfoByRankUpdated(_rank, _maxSamiPoints, _boxes, _affectation);
    }

    function setAmountOfBoxesPerPachaPerDay(uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit BoxesPerDayPerPachaDx(amountOfBoxesPerPachaPerDay, _amount);
        amountOfBoxesPerPachaPerDay = _amount;
    }

    function setAmountOfMinimumSamiPoints(uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit MinimumSamiPointsDx(amountOfMinimumSamiPoints, _amount);
        amountOfMinimumSamiPoints = _amount;
    }

    function setAmountOfMaximumSamiPoints(uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit MaximumSamiPointsDx(amountOfMaximumSamiPoints, _amount);
        amountOfMaximumSamiPoints = _amount;
    }

    function setChakraAddress(address _chakraAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftTypeToAddress[CHAKRA] = _chakraAddress;
        chakraAddress = _chakraAddress;
    }

    function setPoolRewardAddress(address _poolRewardAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        poolRewardAddress = _poolRewardAddress;
    }

    function setHatunWasiAddressAddress(address _hatunWasiAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftTypeToAddress[HATUNWASI] = _hatunWasiAddress;
        hatunWasiAddress = _hatunWasiAddress;
    }

    function setTatacuyAddress(address _tatacuyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftTypeToAddress[TATACUY] = _tatacuyAddress;
        tatacuyAddress = _tatacuyAddress;
    }

    function setWiracochaAddress(address _wiracochaAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftTypeToAddress[WIRACOCHA] = _wiracochaAddress;
        wiracochaAddress = _wiracochaAddress;
    }

    function setAddPAController(address _purchaseACAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        purchaseACAddress = _purchaseACAddress;
    }

    function setPachaCuyTokenAddress(address _pachaCuyTokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyTokenAddress = _pachaCuyTokenAddress;
    }

    function setMisayWasiAddress(address _misayWasiAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftTypeToAddress[MISAYWASI] = _misayWasiAddress;
        nftTypeToAddress[TICKETRAFFLE] = _misayWasiAddress;
        misayWasiAddress = _misayWasiAddress;
    }

    function setNftProducerAddress(address _nftProducerAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftProducerAddress = _nftProducerAddress;
    }

    function setGuineaPigAddress(address _guineaPigAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftTypeToAddress[GUINEAPIG] = _guineaPigAddress;
        guineaPigAddress = _guineaPigAddress;
    }

    function setRandomNumberGAddress(address _randomNumberGAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        randomNumberGAddress = _randomNumberGAddress;
    }

    function setBinarySearchAddress(address _binarySearchAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        binarySearchAddress = _binarySearchAddress;
    }

    function setPachaAddress(address _pachaAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftTypeToAddress[PACHA] = _pachaAddress;
        nftTypeToAddress[PACHAPASS] = _pachaAddress;
        pachaAddress = _pachaAddress;
    }

    function setQhatuWasiAddress(address _qhatuWasiAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftTypeToAddress[QHATUWASI] = _qhatuWasiAddress;
        qhatuWasiAddress = _qhatuWasiAddress;
    }

    //////////////////////////////////////////////////////////////////
    ///                         TAXES/FEES                         ///
    //////////////////////////////////////////////////////////////////

    function setPurchaseTax(uint256 _newTax)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        purchaseTax = _newTax;
    }

    function setRaffleTax(uint256 _newTax)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        raffleTax = _newTax;
    }

    function setQhatuWasiTax(uint256 _newTax)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        qhatuWasiTax = _newTax;
    }

    //////////////////////////////////////////////////////////////////
    ///                       EXCHANGE RATE                        ///
    //////////////////////////////////////////////////////////////////
    function setExchangeRateBusdToPcuy(uint256 _exchangeRateBusdToPcuy)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit ExchangeRateBusdToPcuyDx(
            exchangeRatePcuyToSami,
            _exchangeRateBusdToPcuy
        );
        exchangeRateBusdToPcuy = _exchangeRateBusdToPcuy;
    }

    function setExchangeRatePcuyToSami(uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit ExchangeRatePcuyToSamiDx(exchangeRatePcuyToSami, _amount);
        exchangeRatePcuyToSami = _amount;
    }

    function convertBusdToPcuy(uint256 _busdAmount)
        public
        view
        returns (uint256 _pacuyAmount)
    {
        _pacuyAmount = _busdAmount * exchangeRateBusdToPcuy;
    }

    function convertPcuyToSami(uint256 _pcuyAmount)
        external
        view
        returns (uint256 _samiPoints)
    {
        _samiPoints = (_pcuyAmount * exchangeRatePcuyToSami) / (10**18);
    }

    function convertSamiToPcuy(uint256 _samiAmount)
        external
        view
        returns (uint256 _pcuyAmount)
    {
        _pcuyAmount = (_samiAmount * 10**18) / exchangeRatePcuyToSami;
    }

    function getAddressOfNftType(bytes32 _type)
        external
        view
        returns (address)
    {
        return nftTypeToAddress[_type];
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
