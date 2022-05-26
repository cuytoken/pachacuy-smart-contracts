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
////                                                  Misay Wasi                                                   ////
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
import "../NftProducerPachacuy/INftProducerPachacuy.sol";
import "../purchaseAssetController/IPurchaseAssetController.sol";

/// @custom:security-contact lee@cuytoken.com
contract MisayWasi is
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
     * @param misayWasiUuid: Uuid of the misay waysi when it was minted
     * @param pachaUuid: Uuid of the pacha where the misay waysi belongs to
     * @param creationDate: Date when the misay waysi was minted
     * @param ticketPrice: Price ticket to participate in the raffle
     * @param ticketUuid: Uuid of the ticket of the Misay Wasi
     * @param misayWasiPrice: Price in PCUY of the Misay Wasi
     * @param rafflePrize: Prize of winning at the raffle
     * @param numberTicketsPurchased: Number of raffle tickets bought
     * @param campaignStartDate: Timestamp when the raffle initiated
     * @param campaignEndDate: Timestamp when the raffle ends
     * @param isCampaignActive: Indicates wheter this misay waysi is running a raffle or not
     * @param hasMisayWasi: Indicates wheter a misay wasi exists or not
     */
    struct MisayWasiInfo {
        address owner;
        uint256 misayWasiUuid;
        uint256 pachaUuid;
        uint256 creationDate;
        uint256 ticketPrice;
        uint256 ticketUuid;
        uint256 misayWasiPrice;
        uint256 rafflePrize;
        uint256 numberTicketsPurchased;
        uint256 campaignStartDate;
        uint256 campaignEndDate;
        bool isCampaignActive;
        bool hasMisayWasi;
        address[] listOfParticipants;
    }
    // MisayWasi UUID  -> Struct of MisayWasi Info
    mapping(uint256 => MisayWasiInfo) internal uuidToMisayWasiInfo;

    // List of Available MisayWasis
    MisayWasiInfo[] listOfActiveMWRaffles;
    // MisayWasi uuid => array index
    mapping(uint256 => uint256) internal _misayWasiIx;

    // ticket uuid => wallet address => amount of tickets
    mapping(uint256 => mapping(address => uint256)) listOfRaffleTickets;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(GAME_MANAGER, _msgSender());
    }

    /**
     * @dev Trigger when it is minted
     * @param _account: Wallet address of the current owner of the Pacha
     * @param _pachaUuid: Uuid of the pacha when it was minted
     * @param _misayWasiUuid: Uuid of the Tatacuy when it was minted
     * @param _misayWasiPrice: Price in PCUY of the Misay Wasi
     */
    function registerMisayWasi(
        address _account,
        uint256 _pachaUuid,
        uint256 _misayWasiUuid,
        uint256 _misayWasiPrice
    ) external onlyRole(GAME_MANAGER) {
        MisayWasiInfo memory misayWasiInfo = MisayWasiInfo({
            owner: _account,
            misayWasiUuid: _misayWasiUuid,
            pachaUuid: _pachaUuid,
            creationDate: block.timestamp,
            ticketPrice: 0,
            ticketUuid: 0,
            misayWasiPrice: _misayWasiPrice,
            rafflePrize: 0,
            numberTicketsPurchased: 0,
            campaignStartDate: 0,
            campaignEndDate: 0,
            isCampaignActive: false,
            hasMisayWasi: true,
            listOfParticipants: new address[](0)
        });
        uuidToMisayWasiInfo[_misayWasiUuid] = misayWasiInfo;
    }

    function startMisayWasiRaffle(
        uint256 _misayWasiUuid,
        uint256 _rafflePrize,
        uint256 _ticketPrice,
        uint256 _campaignEndDate
    ) external {
        IPurchaseAssetController(pachacuyInfo.purchaseACAddress())
            .transferPcuyFromUserToPoolReward(_msgSender(), _rafflePrize);

        MisayWasiInfo storage misayWasiInfo = uuidToMisayWasiInfo[
            _misayWasiUuid
        ];

        require(
            !misayWasiInfo.isCampaignActive,
            "Misay Wasi: Campaign is active"
        );

        require(
            misayWasiInfo.owner == _msgSender(),
            "Misay Wasi: Not the owner"
        );

        uint256 _ticketUuid = INftProducerPachacuy(
            pachacuyInfo.nftProducerAddress()
        ).createTicketIdRaffle();

        misayWasiInfo.rafflePrize = _rafflePrize;
        misayWasiInfo.ticketPrice = _ticketPrice;
        misayWasiInfo.campaignEndDate = _campaignEndDate;
        misayWasiInfo.isCampaignActive = true;
        misayWasiInfo.ticketUuid = _ticketUuid;
        misayWasiInfo.campaignStartDate = block.timestamp;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _misayWasiIx[_misayWasiUuid] = current;
        listOfActiveMWRaffles.push(misayWasiInfo);
    }

    function registerTicketPurchase(
        address _account,
        uint256 _ticketUuid,
        uint256 _misayWasiUuid,
        uint256 _amountOfTickets,
        bool newCustomer
    ) external onlyRole(GAME_MANAGER) {
        listOfRaffleTickets[_ticketUuid][_account] += _amountOfTickets;

        MisayWasiInfo storage misayWasiInfo = uuidToMisayWasiInfo[
            _misayWasiUuid
        ];

        misayWasiInfo.numberTicketsPurchased += _amountOfTickets;

        if (newCustomer) {
            uint256 _l = misayWasiInfo.listOfParticipants.length;
            misayWasiInfo.listOfParticipants[_l] = _account;
        }
    }

    // function purchase
    // start contest
    //

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function setPachacuyInfoAddress(address _infoAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachacuyInfo = IPachacuyInfo(_infoAddress);
    }

    function getMisayWasiWithUuid(uint256 _misayWasiUuid)
        external
        view
        returns (MisayWasiInfo memory)
    {
        return uuidToMisayWasiInfo[_misayWasiUuid];
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
