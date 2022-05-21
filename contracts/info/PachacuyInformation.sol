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

    // Contract addresses
    address public chakraAddress;
    address public poolRewardAddress;
    address public hatunWasiAddress;
    address public wiracochaAddress;
    address public tatacuyAddress;
    address public purchaseACAddress;
    address public pachaCuyTokenAddress;

    // Asset Management
    uint256 public purchaseTax;

    // Magical Boxes
    uint256 public amountOfBoxesPerPachaPerDay;
    uint256 public amountOfMinimumSamiPoints;
    uint256 public amountOfMaximumSamiPoints;

    // Business Prices in BUSD
    uint256 public chakraPrice;
    uint256 public pachaPrice;
    uint256 public qhatuWasiPrice;
    uint256 public misayWasiPrice;

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

        // Food at chakra
        totalFood = 12;
        pricePerFood = 25 * 10e18;

        // business prices en BUSD
        chakraPrice = 10 * 10e18;
        pachaPrice = 200 * 10e18;
        qhatuWasiPrice = 3 * 10e18;
        misayWasiPrice = 10 * 10e18;

        // rates
        // 1 BUSD = 25 PCUY
        exchangeRateBusdToPcuy = 25;
        // 100 sami points = 1 BUSD
        // 1 BUSD = 25 PCUY
        // 1 PCUY = 4 sami points
        exchangeRatePcuyToSami = 4;
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

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
        hatunWasiAddress = _hatunWasiAddress;
    }

    function setTatacuyAddress(address _tatacuyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tatacuyAddress = _tatacuyAddress;
    }

    function setWiracochaAddress(address _wiracochaAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
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

    function setPurchaseTax(uint256 _purchaseTax)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        purchaseTax = _purchaseTax;
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
        external
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
        _samiPoints = (_pcuyAmount / 10e18) * exchangeRatePcuyToSami;
    }

    function convertSamiToPcuy(uint256 _samiAmount)
        external
        view
        returns (uint256 _pcuyAmount)
    {
        _pcuyAmount = (_samiAmount / exchangeRatePcuyToSami) * 10e18;
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