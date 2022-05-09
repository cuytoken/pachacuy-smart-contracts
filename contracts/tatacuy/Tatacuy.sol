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
////                                                   Tatacuy                                                   ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../vrf/IRandomNumberGenerator.sol";
import "../purchaseAssetController/IPurchaseAssetController.sol";

/// @custom:security-contact lee@cuytoken.com
contract Tatacuy is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");
    bytes32 public constant RNG_GENERATOR = keccak256("RNG_GENERATOR");

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    IRandomNumberGenerator public randomNumberGenerator;
    IPurchaseAssetController public purchaseAssetController;

    // RandomTranasction
    struct RandomTx {
        address pachaOwner;
        uint256 pachaUuid;
        uint256 tatacuyUuid;
        address account;
        uint256 likelihood;
    }
    mapping(address => RandomTx) internal _randomTxs;

    struct TatacuyInfo {
        address owner;
        uint256 tatacuyUuid;
        uint256 pachaUuid;
        uint256 creationDate;
        uint256 totalFundsPcuyDeposited;
        uint256 ratePcuyToSamiPoints;
        uint256 totalFundsSamiPoints;
        uint256 prizePerWinnerSamiPoints;
        uint256 totalSamiPointsClaimed;
        uint256 campaignStartDate;
        uint256 campaignEndDate;
        bool hasTatacuy;
        bool isCampaignActive;
    }
    // Owner Tatacuy -> Pacha UUID -> Tatacuy UUID  -> Struct of Campaign Info
    mapping(address => mapping(uint256 => TatacuyInfo)) ownerToTatacuy;

    // List of all active campaigns at any given time
    TatacuyInfo[] internal listActiveCampaigns;

    // Owner => tatacuy UUID => array index of 'listActiveCampaigns'
    mapping(address => mapping(uint256 => uint256)) internal _campaignIx;

    event TatacuyCampaignStarted(
        address account,
        uint256 totalFundsPcuyDeposited,
        uint256 ratePcuyToSamiPoints,
        uint256 totalFundsSamiPoints,
        uint256 prizePerWinnerSamiPoints,
        uint256 dateOfCreation
    );

    event TatacuyTryMyLuckResult(
        address account,
        bool hasWon,
        uint256 likelihood,
        uint256 pachaUuid,
        uint256 tatacuyUuid,
        address pachaOwner
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _randomNumberGeneratorAddress)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        randomNumberGenerator = IRandomNumberGenerator(
            _randomNumberGeneratorAddress
        );

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
    }

    function registerTatacuy(
        address _account,
        uint256 _pachaUuid,
        uint256 _tatacuyUuid,
        bytes memory
    ) external onlyRole(GAME_MANAGER) {
        require(
            !ownerToTatacuy[_account][_pachaUuid].hasTatacuy,
            "Tatacuy: Already exists one for this pacha"
        );

        ownerToTatacuy[_account][_pachaUuid] = TatacuyInfo({
            owner: _account,
            tatacuyUuid: _tatacuyUuid,
            pachaUuid: _pachaUuid,
            creationDate: block.timestamp,
            totalFundsPcuyDeposited: 0,
            ratePcuyToSamiPoints: 0,
            totalFundsSamiPoints: 0,
            prizePerWinnerSamiPoints: 0,
            totalSamiPointsClaimed: 0,
            campaignStartDate: 0,
            campaignEndDate: 0,
            hasTatacuy: true,
            isCampaignActive: false
        });
    }

    /**
     * @dev Starts a Tatacuy Campaign for a particular account and saves its info
     * @dev A user can create as many campaigns as Tatacuys he has
     * @param _pachaUuid: Uuid of the Pacha that will received a Tatacuy
     * @param _tatacuyUuid: Uuid assigned when a Tatacuy was minted
     * @param _totalFundsPcuyDeposited: Total funds (in Sami Points) to be distributed in a Tatacuy campaign
     * @param _ratePcuyToSamiPoints: Total funds (in Sami Points) to be distributed in a Tatacuy campaign
     * @param _totalFundsSamiPoints: Total funds (in Sami Points) to be distributed in a Tatacuy campaign
     * @param _prizePerWinnerSamiPoints: Prize (in Sami Points) to be given to a winner after playing at Tatacuy
     */
    function startTatacuyCampaign(
        uint256 _pachaUuid,
        uint256 _tatacuyUuid,
        uint256 _totalFundsPcuyDeposited,
        uint256 _ratePcuyToSamiPoints,
        uint256 _totalFundsSamiPoints,
        uint256 _prizePerWinnerSamiPoints
    ) external {
        TatacuyInfo storage tatacuyInfo = ownerToTatacuy[_msgSender()][
            _pachaUuid
        ];
        require(
            tatacuyInfo.owner == _msgSender(),
            "Tatacuy: only owner starts campaign"
        );

        require(
            !tatacuyInfo.isCampaignActive,
            "Tatacuy: campaign is already active"
        );

        tatacuyInfo.totalFundsPcuyDeposited = _totalFundsPcuyDeposited;
        tatacuyInfo.ratePcuyToSamiPoints = _ratePcuyToSamiPoints;
        tatacuyInfo.totalFundsSamiPoints = _totalFundsSamiPoints;
        tatacuyInfo.prizePerWinnerSamiPoints = _prizePerWinnerSamiPoints;
        tatacuyInfo.campaignStartDate = block.timestamp;
        tatacuyInfo.isCampaignActive = true;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        listActiveCampaigns[current] = tatacuyInfo;
        _campaignIx[_msgSender()][_tatacuyUuid] = current;

        emit TatacuyCampaignStarted(
            _msgSender(),
            _totalFundsPcuyDeposited,
            _ratePcuyToSamiPoints,
            _totalFundsSamiPoints,
            _prizePerWinnerSamiPoints,
            block.timestamp
        );

        purchaseAssetController.transferPcuyFromUserToPoolReward(
            _msgSender(),
            _totalFundsPcuyDeposited
        );
    }

    function finishTatacuyCampaign(uint256 _pachaUuid)
        external
        returns (uint256)
    {
        TatacuyInfo storage tatacuyInfo = ownerToTatacuy[_msgSender()][
            _pachaUuid
        ];

        require(tatacuyInfo.hasTatacuy, "Tatacuy: There is not a Tatacuy");

        require(
            tatacuyInfo.isCampaignActive,
            "Tatacuy: No campaign for account"
        );

        // 1 - reset info about campaign
        uint256 _total = tatacuyInfo.totalFundsSamiPoints;
        uint256 _claimed = tatacuyInfo.totalSamiPointsClaimed;
        tatacuyInfo.isCampaignActive = false;
        tatacuyInfo.totalFundsPcuyDeposited = 0;
        tatacuyInfo.ratePcuyToSamiPoints = 0;
        tatacuyInfo.totalFundsSamiPoints = 0;
        tatacuyInfo.prizePerWinnerSamiPoints = 0;
        tatacuyInfo.campaignEndDate = block.timestamp;

        // 2 - delete from list of campaigns
        uint256 _ix = _campaignIx[_msgSender()][tatacuyInfo.tatacuyUuid];
        delete _campaignIx[_msgSender()][tatacuyInfo.tatacuyUuid];

        if (listActiveCampaigns.length == 1) {
            listActiveCampaigns.pop();
            _tokenIdCounter.decrement();
            // get back the sami points
            return _total - _claimed;
        }

        TatacuyInfo memory _last = listActiveCampaigns[
            listActiveCampaigns.length - 1
        ];
        listActiveCampaigns[_ix] = _last;
        listActiveCampaigns.pop();
        _campaignIx[_last.owner][_last.tatacuyUuid] = _ix;
        _tokenIdCounter.decrement();

        // get back the sami points
        return _total - _claimed;
    }

    /**
     * @notice A guineapig could win Sami Points after trying luck at a Tatacuy
     * @dev It uses a Random Number Generator by Chainlink and the `_likelihood`
     * @param _account: The address for which random number request has been made
     * @param _pachaOwner: Wallet address of the pacha at which this Tatacuy is placed
     * @param _pachaUuid: Uuid of the pacha received when it was minted
     * @param _tatacuyUuid: Uuid of the Tatacuy received when it was minted
     * @param _likelihood: A number between 1 and 10 in inclusive that represents tha chances of winning
     */
    function tryMyLuckTatacuy(
        address _account,
        address _pachaOwner,
        uint256 _pachaUuid,
        uint256 _tatacuyUuid,
        uint256 _likelihood
    ) external onlyRole(GAME_MANAGER) {
        TatacuyInfo storage tatacuyInfo = ownerToTatacuy[_pachaOwner][
            _pachaUuid
        ];

        require(
            tatacuyInfo.isCampaignActive,
            "Tatacuy: campaign is not active"
        );

        require(
            (tatacuyInfo.totalSamiPointsClaimed +
                tatacuyInfo.prizePerWinnerSamiPoints) <=
                tatacuyInfo.totalFundsSamiPoints,
            "Tatacuy: not enough Sami points"
        );

        require(
            _likelihood > 0 && _likelihood < 11,
            "Tatacuy: number must be between 1 and 10"
        );

        _randomTxs[_account] = RandomTx({
            pachaOwner: _pachaOwner,
            pachaUuid: _pachaUuid,
            tatacuyUuid: _tatacuyUuid,
            account: _account,
            likelihood: _likelihood
        });

        tatacuyInfo.totalSamiPointsClaimed += tatacuyInfo
            .prizePerWinnerSamiPoints;

        // Ask for one random number
        randomNumberGenerator.requestRandomNumber(_account);
    }

    // Callback from VRF
    function fulfillRandomness(
        address _account,
        uint256[] memory _randomNumbers
    ) external onlyRole(RNG_GENERATOR) {
        uint256 randomNumber = (_randomNumbers[0] % 10) + 1;
        uint256 _likelihood = _randomTxs[_account].likelihood;

        emit TatacuyTryMyLuckResult(
            _account,
            randomNumber <= _likelihood,
            _likelihood,
            _randomTxs[_account].pachaUuid,
            _randomTxs[_account].tatacuyUuid,
            _randomTxs[_account].pachaOwner
        );

        delete _randomTxs[_account];
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function getTatacuyInfoForAccount(address _account, uint256 _pachaUuid)
        external
        view
        returns (TatacuyInfo memory)
    {
        return ownerToTatacuy[_account][_pachaUuid];
    }

    function getListOfTatacuyCampaigns()
        external
        view
        returns (TatacuyInfo[] memory)
    {
        return listActiveCampaigns;
    }

    function setAddressPurchaseAssetController(address _purchaseAssetController)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        purchaseAssetController = IPurchaseAssetController(
            _purchaseAssetController
        );
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
