// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../random/IRandomGenerator.sol";

/// @custom:security-contact lee@cuytoken.com
contract RewardsCenter is
    IRandomGenerator,
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ENTREPRENEUR_ROLE = keccak256("ENTREPRENEUR_ROLE");

    IERC20Upgradeable public pachacuyToken;
    IRandomGenerator public randomGenerator;

    bytes32 requestId;
    uint256 randomness;

    uint256 private constant FIGURING_OUT_WINNER = 999999;

    /**
     * @note Only one Reward Contest is run at any given time
     * @param rewardContestCreator: Creator of the Reward Contest
     * @param poolReward: Total pool to be put on the Reward Contest
     * @param prizePerSuccess: Each winner's prize when he succeeds
     * @param successRatio: Success ratio for each try. It goes from 1 to 99
     * @param currentlyActive: Shows if current Reward Contest is running
     */
    struct RewardContestStruct {
        string nameRewardContest;
        address rewardContestCreator;
        uint256 poolReward;
        uint256 prizePerSuccess;
        uint256 successRatio;
        bool currentlyActive;
    }

    struct ContestParitipantStruct {
        address contestParticipant;
        address ownerOfContestPlayed;
        uint256 lastTimePlayed;
        bool currentlyParticipating;
        bytes32 requestIdRandomNum;
    }

    struct RandomResultStruct {
        bool inProcess;
        bool completed;
        uint256 result;
    }

    /**
     * @dev Maps 'requestId', which comes from calculating a random number
     */
    mapping(bytes32 => address) private winnersRequestId;
    mapping(address => RandomResultStruct) private winnersResult;

    mapping(address => RewardContestStruct) rewardContestsInfo;

    /**
     * @dev Maps contest participant addresses to owner address to Contest Info
     * participant => owner => participant info
     */
    mapping(address => mapping(address => ContestParitipantStruct)) contestParticipants;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _pachaCuyTokenAddress,
        address _randomGeneratorAddress
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        pachacuyToken = IERC20Upgradeable(_pachaCuyTokenAddress);
        randomGenerator = IRandomGenerator(_randomGeneratorAddress);
    }

    function initialize2(
        address _pachaCuyTokenAddress,
        address _randomGeneratorAddress
    ) public {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        pachacuyToken = IERC20Upgradeable(_pachaCuyTokenAddress);
        randomGenerator = IRandomGenerator(_randomGeneratorAddress);
    }

    /**
     * @notice Creates a Reward Contest
     * @dev Creator needs to deposit some funds to create the Reward's Pool
     * IMPORTANT: Caller of this function need to call 'approve' the contract address in order 'transferFrom' to succeed
     * @param _nameRewardContest: Name of the reward contest
     * @param _poolReward: Pool funded by the cretor of the Reward Contest
     * @param _prizePerSuccess: Prize each winner will claim if he wins
     * @param _successRatio: Ratio of success per try. Values between 1 to 99 out of 100
     */
    function createRewardContest(
        string memory _nameRewardContest,
        uint256 _poolReward,
        uint256 _prizePerSuccess,
        uint256 _successRatio
    ) public onlyRole(ENTREPRENEUR_ROLE) {
        require(
            !rewardContestsInfo[_msgSender()].currentlyActive,
            "Reward C.: One Reward Contest at a time only."
        );

        uint256 balancePachacuy = pachacuyToken.balanceOf(_msgSender());
        require(
            balancePachacuy >= _poolReward,
            "Rewards C.: Not enough Pachacuy balance to create Reward Contest."
        );

        require(
            _successRatio >= 1 && _successRatio <= 99,
            "Rewards C.: Prize per success must be between 1 and 99 inclusive."
        );

        uint256 allowanceToContract = pachacuyToken.allowance(
            _msgSender(),
            address(this)
        );
        require(
            allowanceToContract >= _poolReward,
            "Rewards C.: As creator, you must approve this contract to spend tokens on your behalf."
        );

        pachacuyToken.transferFrom(_msgSender(), address(this), _poolReward);

        rewardContestsInfo[_msgSender()] = RewardContestStruct(
            _nameRewardContest,
            _msgSender(),
            _poolReward,
            _prizePerSuccess,
            _successRatio,
            true
        );
    }

    function participateInRewardContest(address _ownerContestReward) public {
        require(
            rewardContestsInfo[_ownerContestReward].poolReward >=
                rewardContestsInfo[_ownerContestReward].prizePerSuccess,
            "Rewards C.: Not enough balance in pool contest for rewarding."
        );

        require(
            rewardContestsInfo[_ownerContestReward].rewardContestCreator !=
                _msgSender(),
            "Rewards Center: Creator cannot participate in his contest."
        );

        require(
            !contestParticipants[_msgSender()][_ownerContestReward]
                .currentlyParticipating,
            "Rewards Center: You are already participating in this Reward Contest."
        );

        require(
            contestParticipants[_msgSender()][_ownerContestReward]
                .lastTimePlayed +
                1 days >=
                block.timestamp,
            "Rewards Center: Only one try per day is allowed"
        );

        bytes32 _requestId = getRandomNumber();
        contestParticipants[_msgSender()][
            _ownerContestReward
        ] = ContestParitipantStruct(
            _msgSender(),
            _ownerContestReward,
            block.timestamp,
            true,
            _requestId
        );
    }

    /**
     * @dev Verifies whether a Guinea Pig is a winner
     * @param _ownerContestReward: address of the Creator of the Contest Reward
     */
    function verifyWinnerContestReward(address _ownerContestReward)
        public
        view
        returns (uint256)
    {
        // 0 -> There is no contest in progress for the caller
        if (
            !winnersResult[_msgSender()].inProcess &&
            !winnersResult[_msgSender()].inProcess
        ) {
            return 0;
        }

        // 1 -> verification in process
        if (winnersResult[_msgSender()].inProcess) {
            return 1;
        }

        if (winnersResult[_msgSender()].completed) {
            uint256 _result = winnersResult[_msgSender()].result;
            uint256 _successRatio = rewardContestsInfo[_ownerContestReward]
                .successRatio;
            if (_result <= _successRatio) {
                // 3 -> won the contest
                return 3;
            }
            // 2 -> lost the contest
            return 2;
        }
        return 0;
    }

    /**
     * @dev Verifies whether a Guinea Pig is a winner and claims the prize of a Contest Reward
     * @param _ownerContestReward: address of the Creator of the Contest Reward
     */
    function claimPrizeFromRewardContest(address _ownerContestReward)
        public
        returns (uint256)
    {
        require(
            !winnersResult[_msgSender()].inProcess,
            "Reward C.: Winner verification for address is on progress."
        );

        require(
            rewardContestsInfo[_ownerContestReward].poolReward >=
                rewardContestsInfo[_ownerContestReward].prizePerSuccess,
            "Rewards C.: Not enough balance in pool contest for rewarding."
        );

        if (winnersResult[_msgSender()].completed) {
            contestParticipants[_msgSender()][_ownerContestReward]
                .currentlyParticipating = false;

            // result is between 1 to 99
            uint256 _result = winnersResult[_msgSender()].result;

            RewardContestStruct storage _rewardContestInfo = rewardContestsInfo[
                _ownerContestReward
            ];
            if (_result <= _rewardContestInfo.successRatio) {
                // winner
                pachacuyToken.transfer(
                    _msgSender(),
                    _rewardContestInfo.prizePerSuccess
                );

                _rewardContestInfo.poolReward -= _rewardContestInfo
                    .prizePerSuccess;

                return _rewardContestInfo.prizePerSuccess;
            }
            winnersResult[_msgSender()] = RandomResultStruct(false, false, 0);
            return 0;
        } else {
            winnersResult[_msgSender()] = RandomResultStruct(true, false, 0);
            bytes32 _requestId = randomGenerator.getRandomNumber();
            winnersRequestId[_requestId] = _msgSender();
        }
        return 0;
    }

    /**
     * @dev Close a Reward Contest created by a 'Entrepreneur'.
     * Only one Reward Contest is run at a time.
     * Any leftover balance in the contest pool is sent back to the creator contest
     */
    function closeRewardContest() public onlyRole(ENTREPRENEUR_ROLE) {
        RewardContestStruct storage _rewardContestInfo = rewardContestsInfo[
            _msgSender()
        ];
        require(
            _rewardContestInfo.rewardContestCreator == _msgSender(),
            "Reward C.: Only the owner could close a Reward Contest."
        );
        require(
            _rewardContestInfo.currentlyActive,
            "Reward C.: Reward contest to be closed should be running."
        );

        if (_rewardContestInfo.poolReward >= 0) {
            pachacuyToken.transfer(_msgSender(), _rewardContestInfo.poolReward);
            _rewardContestInfo.poolReward = 0;
        }
        _rewardContestInfo.currentlyActive = false;
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        public
        override
    {
        // _result is between 1 and 99
        uint256 _result = _randomness.mod(100).add(1);
        winnersResult[winnersRequestId[_requestId]] = RandomResultStruct(
            false,
            true,
            _result
        );
    }

    function getRandomNumber() public override returns (bytes32 _requestId) {
        _requestId = randomGenerator.getRandomNumber();
        requestId = _requestId;
        return _requestId;
    }

    /**
     * @notice Assigns the 'Entrepreneur' role to an account. An 'Entrepreneur' is able to own lands and purchase assets
     * @dev _account changes a to 'Entrepreneur' role. Only callable by Admin
     * @param _account to be upgrade to 'Entrepreneur'
     */
    function upgradeRoleToEntrepreneur(address _account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(ENTREPRENEUR_ROLE, _account);
    }

    /**
     * @notice Revokes the 'Entrepreneur' role to an account. An 'Entrepreneur' is able to own lands and purchase assets
     * @dev _account changes a to 'Entrepreneur' role. Only callable by Admin
     * @param _account to be upgrade to 'Entrepreneur'
     */
    function revokeRoleEntrepreneur(address _account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(ENTREPRENEUR_ROLE, _account);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
