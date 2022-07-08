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
import "../info/IPachacuyInfo.sol";

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

    // Pachacuy Information
    IPachacuyInfo pachacuyInfo;

    // RandomTranasction
    struct RandomTx {
        address pachaOwner;
        uint256 pachaUuid;
        uint256 tatacuyUuid;
        uint256 prizeWinner;
        address account;
        uint256 likelihood;
        uint256 idFromFront;
    }
    mapping(address => RandomTx) internal _randomTxs;

    /**
     * @dev Details the information of a Tatacuy. Additional properties attached for its campaign
     * @param owner: Wallet address of the current owner of the Tatacuy
     * @param tatacuyUuid: Uuid of the Tatacuy when it was minted
     * @param pachaUuid: Uuid of the pacha where this Tatacuy is located
     * @param creationDate: Timestamp of the Tatacuy when it was minted
     * @param totalFundsPcuyDeposited: Amount of PCUYs deposited when a Tatacuy campaign was created
     * @param ratePcuyToSamiPoints: Exchange rate from PCUY token to Sami Points when Tatacuy campaign was created
     * @param totalFundsSamiPoints: Amount of Sami Points (converted from PCUY tokens) assignated for the campaign
     * @param prizePerWinnerSamiPoints: Amount of Sami Points each winner will receive
     * @param totalSamiPointsClaimed: Accumulates Sami Points after a player wins at a Tatacuy Game
     * @param campaignStartDate: Timestamp when the campaign started
     * @param campaignEndDate: Timestamp when the campaign ended
     * @param hasTatacuy: Whether a Tatacuy exists or not
     * @param isCampaignActive: Indicates if there is an active Tatacuy campaign
     */
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
    // Pacha UUID -> Tatacuy UUID  -> Struct of Tatacuy Info
    mapping(uint256 => TatacuyInfo) uuidToTatacuyInfo;

    // List of all Uuid active campaigns at any given time
    uint256[] internal listUuidActiveCampaigns;

    // Owner => tatacuy UUID => array index of 'listUuidActiveCampaigns'
    mapping(uint256 => uint256) internal _campaignIx;

    event TatacuyCampaignStarted(
        address account,
        uint256 totalFundsPcuyDeposited,
        uint256 _prizePerWinnerPcuy
    );

    /**
     * @notice Event emitted when there is a result from playing at Tatacuy
     * @param account: wallet address of the player at tatacuy
     * @param hasWon: indicates (boolean) whether the player has won or loose
     * @param prizeWinner: amount of sami points to be given to the winner
     * @param likelihood: chances of winning at Tatacuy (1 to 10)
     * @param pachaUuid: uuid of the pacha when it was minted
     * @param tatacuyUuid: uuid of the tatacuy when it was minted
     * @param pachaOwner: wallet address of the pacha owner
     * @param idFromFront: An ID coming from front to keep track of the winner at Tatacuy
     */
    event TatacuyTryMyLuckResult(
        address account,
        bool hasWon,
        uint256 prizeWinner,
        uint256 likelihood,
        uint256 pachaUuid,
        uint256 tatacuyUuid,
        address pachaOwner,
        uint256 idFromFront
    );

    /**
     * @notice Event emitted when the tatacuy owner closes a Tatacuy campaign
     * @param tatacuyOwner: wallet address of the tatacuy owner
     * @param totalSamiPoints: total funds deposited in sami points
     * @param samiPointsClaimed: total funds claimed in sami points
     * @param changeSamiPoints: change back in sami points
     */
    event FinishTatacuyCampaign(
        address tatacuyOwner,
        uint256 totalSamiPoints,
        uint256 samiPointsClaimed,
        uint256 changeSamiPoints
    );

    event MintTatacuy(
        address owner,
        uint256 tatacuyUuid,
        uint256 pachaUuid,
        uint256 creationDate
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

    /**
     * @dev Trigger when it is minted
     * @param _account: Wallet address of the current owner of the Pacha
     * @param _pachaUuid: Uuid of the pacha when it was minted
     * @param _tatacuyUuid: Uuid of the Tatacuy when it was minted
     */
    function registerTatacuy(
        address _account,
        uint256 _pachaUuid,
        uint256 _tatacuyUuid,
        bytes memory
    ) external onlyRole(GAME_MANAGER) {
        uuidToTatacuyInfo[_tatacuyUuid] = TatacuyInfo({
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

        emit MintTatacuy(_account, _tatacuyUuid, _pachaUuid, block.timestamp);
    }

    /**
     * @dev Starts a Tatacuy Campaign for a particular account and saves its info
     * @dev A user can create as many campaigns as Tatacuys he has
     * @param _tatacuyUuid: Uuid assigned when a Tatacuy was minted
     * @param _totalFundsPcuyDeposited: Total funds (in PCUY) to be distributed in a Tatacuy campaign
     * @param _prizePerWinnerPcuy: Prize to be given (in PCUY) to each winner at tatacuy
     */
    function startTatacuyCampaign(
        uint256 _tatacuyUuid,
        uint256 _totalFundsPcuyDeposited,
        uint256 _prizePerWinnerPcuy
    ) external {
        TatacuyInfo storage tatacuyInfo = uuidToTatacuyInfo[_tatacuyUuid];
        require(
            tatacuyInfo.owner == _msgSender(),
            "Tatacuy: only owner starts campaign"
        );

        require(
            !tatacuyInfo.isCampaignActive,
            "Tatacuy: campaign is already active"
        );

        tatacuyInfo.totalFundsPcuyDeposited = _totalFundsPcuyDeposited;
        tatacuyInfo.ratePcuyToSamiPoints = pachacuyInfo
            .exchangeRatePcuyToSami();
        tatacuyInfo.totalFundsSamiPoints = pachacuyInfo.convertPcuyToSami(
            _totalFundsPcuyDeposited
        );
        tatacuyInfo.prizePerWinnerSamiPoints = pachacuyInfo.convertPcuyToSami(
            _prizePerWinnerPcuy
        );
        tatacuyInfo.campaignStartDate = block.timestamp;
        tatacuyInfo.isCampaignActive = true;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        listUuidActiveCampaigns.push(current);
        _campaignIx[_tatacuyUuid] = current;

        emit TatacuyCampaignStarted(
            _msgSender(),
            _totalFundsPcuyDeposited,
            _prizePerWinnerPcuy
        );

        IPurchaseAssetController(pachacuyInfo.purchaseACAddress())
            .transferPcuyFromUserToPoolReward(
                _msgSender(),
                _totalFundsPcuyDeposited
            );
    }

    function finishTatacuyCampaign(uint256 _tatacuyUuid) external {
        TatacuyInfo storage tatacuyInfo = uuidToTatacuyInfo[_tatacuyUuid];

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
        tatacuyInfo.totalSamiPointsClaimed = 0;
        tatacuyInfo.prizePerWinnerSamiPoints = 0;
        tatacuyInfo.campaignEndDate = block.timestamp;

        assert(_total >= _claimed);

        emit FinishTatacuyCampaign(
            _msgSender(),
            _total,
            _claimed,
            _total - _claimed
        );

        // 2 - delete from list of campaigns
        uint256 _ix = _campaignIx[tatacuyInfo.tatacuyUuid];
        delete _campaignIx[tatacuyInfo.tatacuyUuid];

        if (listUuidActiveCampaigns.length == 1) {
            listUuidActiveCampaigns.pop();
            _tokenIdCounter.decrement();
            return;
        }

        uint256 _last = listUuidActiveCampaigns[
            listUuidActiveCampaigns.length - 1
        ];
        listUuidActiveCampaigns[_ix] = _last;
        listUuidActiveCampaigns.pop();
        _campaignIx[_last] = _ix;
        _tokenIdCounter.decrement();
    }

    /**
     * @notice A guineapig could win Sami Points after trying luck at a Tatacuy
     * @notice It's executed by a relayer in the cloud upon signature from the user
     * @dev It uses a Random Number Generator by Chainlink and the `_likelihood`
     * @param _account: The address for which random number request has been made
     * @param _likelihood: A number between 1 and 10 in inclusive that represents tha chances of winning
     * @param _idFromFront: An ID coming from front to keep track of the winner at Tatacuy
     */
    function tryMyLuckTatacuy(
        address _account,
        uint256 _likelihood,
        uint256 _idFromFront,
        uint256 _tatacuyUuid
    ) external onlyRole(GAME_MANAGER) {
        TatacuyInfo storage tatacuyInfo = uuidToTatacuyInfo[_tatacuyUuid];

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
            pachaOwner: tatacuyInfo.owner,
            pachaUuid: tatacuyInfo.pachaUuid,
            tatacuyUuid: tatacuyInfo.tatacuyUuid,
            prizeWinner: tatacuyInfo.prizePerWinnerSamiPoints,
            account: _account,
            likelihood: _likelihood,
            idFromFront: _idFromFront
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
        RandomTx memory randomTx = _randomTxs[_account];

        if (randomNumber <= randomTx.likelihood) {
            emit TatacuyTryMyLuckResult(
                _account,
                true,
                randomTx.likelihood,
                randomTx.prizeWinner,
                randomTx.pachaUuid,
                randomTx.tatacuyUuid,
                randomTx.pachaOwner,
                randomTx.idFromFront
            );
        } else {
            emit TatacuyTryMyLuckResult(
                _account,
                false,
                randomTx.likelihood,
                0,
                randomTx.pachaUuid,
                randomTx.tatacuyUuid,
                randomTx.pachaOwner,
                randomTx.idFromFront
            );
        }

        delete _randomTxs[_account];
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    /**
     * @dev Retrives the list of all active Tatacuy campaigns
     * @notice A campaign is when a Tatacuy is giving away prizes to Guinea Pigs
     * @param _tatacuyUuid: Uuid of the Tatacuy when it was minted
     * @return Gives back an object with the structure of 'TatacuyInfo'
     */
    function getTatacuyWithUuid(uint256 _tatacuyUuid)
        external
        view
        returns (TatacuyInfo memory)
    {
        return uuidToTatacuyInfo[_tatacuyUuid];
    }

    /**
     * @dev Retrives the list of all active Tatacuy campaigns
     * @notice A campaign is when a Tatacuy is giving away prizes to Guinea Pigs
     * @return listActiveCampaigns Gives back an array of objectes with the structure of 'TatacuyInfo'
     */
    function getListOfTatacuyCampaigns()
        external
        view
        returns (TatacuyInfo[] memory listActiveCampaigns)
    {
        listActiveCampaigns = new TatacuyInfo[](listUuidActiveCampaigns.length);
        for (uint256 ix = 0; ix < listUuidActiveCampaigns.length; ix++) {
            listActiveCampaigns[ix] = uuidToTatacuyInfo[
                listUuidActiveCampaigns[ix]
            ];
        }
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
