// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract Vesting is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    // Managing contracts
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Vesting Roles
    bytes32 public constant MARKETING_ADV_ROLE =
        keccak256("MARKETING_ADV_ROLE");
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    bytes32 public constant CUYTOKEN_ROLE = keccak256("CUYTOKEN_ROLE");

    using SafeMathUpgradeable for uint256;

    // VESTING`
    // Each person vesting info
    struct VestingPerAccount {
        bool isVesting;
        uint256 fundsToVestForThisAccount;
        uint256 currentVestingPeriod;
        uint256 totalFundsVested;
        uint256[] datesForVesting;
        string typeOfAccount;
    }
    uint128 vestingPeriods;
    uint128 gapBetweenVestingPeriods; // expressed in months
    mapping(address => VestingPerAccount) vestingAccounts;

    // pachacuy token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable pachaCuyToken;

    // vesting funds for two roles: mkt/adv and team
    struct Funds {
        uint256 team;
        uint256 mktAndAdvisors;
        uint256 airdrop;
        uint256 cuyToken;
    }

    // Funds for allocation - cap
    Funds fundsForAllocation;
    // Funds effectively allocated
    Funds fundsAllocated;

    // VOTING
    event Vote(
        address voter,
        bytes32 hashId,
        string descriptionProposal,
        bool aFavor
    );

    event ProposalDecision(
        bytes32 hashId,
        string description,
        bool approved,
        uint256 totalInFavor,
        uint256 totalAgainst
    );

    event VotingProposalCreated(
        address creator,
        bytes32 hashId,
        string description,
        uint256 creationTime,
        uint256 endingTime
    );
    struct VotingProposal {
        bytes32 hashId;
        string votingProposalDescription;
        uint256 creationDate;
        uint256 duration;
        address[] votersInFavor;
        address[] votersAgainst;
        bool approved; // Whether proposal has been approved or not
    }
    mapping(bytes32 => VotingProposal) proposals;
    mapping(bytes32 => mapping(address => bool)) hasVotedList;
    bytes32[] hashIdOfProposalsList = new bytes32[](0);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint128 _vestingPeriods,
        uint128 _gapBetweenVestingPeriods
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());

        // vesting
        vestingPeriods = _vestingPeriods;
        gapBetweenVestingPeriods = _gapBetweenVestingPeriods;
        settingVestingStateStructs();
    }

    //////////////////////////////////////////////////////////////////////////
    /////////////////////////// Vesting Process //////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    function settingVestingStateStructs() private {
        // Total funds for allocation - cap
        fundsForAllocation = Funds(
            12 * million() * 10**getDecimals(), // 12 M - TEAM
            7 * million() * 10**getDecimals(), //  7 M - MARKEING/ADV/PART
            1 * million() * 10**getDecimals(), //  1 M - AIRDROP
            2 * million() * 10**getDecimals() //  2 M - CUYTOKEN
        );

        // Funds effectively allocated
        fundsAllocated = Funds(0, 0, 0, 0);
    }

    function createVestingSchema(
        address _account,
        uint256 _fundsToVest,
        string memory _typeOfAccount
    ) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _bytes32(_typeOfAccount) == TEAM_ROLE ||
                _bytes32(_typeOfAccount) == AIRDROP_ROLE ||
                _bytes32(_typeOfAccount) == CUYTOKEN_ROLE,
            "Vesting: Solo se puede crear esquemas para TEAM_ROLE, CUYTOKEN_ROLE o AIRDROP_ROLE."
        );

        _createVestingSchema(_account, _fundsToVest, _typeOfAccount);
    }

    function createVestingSchemaWithApproval(
        address _account,
        uint256 _fundsToVest,
        string memory _typeOfAccount,
        bytes32 _hashId
    ) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            proposals[_hashId].approved,
            "Vesting: Esta propuesta no ha sido computada o aprobada"
        );

        require(
            _bytes32(_typeOfAccount) == MARKETING_ADV_ROLE,
            "Vesting: Solo se puede crear esquemas con aprobacion para MARKETING_ADV_ROLE."
        );

        _createVestingSchema(_account, _fundsToVest, _typeOfAccount);
    }

    function _createVestingSchema(
        address _account,
        uint256 _fundsToVest,
        string memory _typeOfAccount
    ) internal {
        // verify that account is not vesting
        require(
            !vestingAccounts[_account].isVesting,
            "Vesting: This account already has a vesting schema."
        );

        // verify roles
        require(
            _isAValidRole(_typeOfAccount),
            "Vesting: Only MARKETING_ADV_ROLE, TEAM_ROLE, AIRDROP_ROLE, CUYTOKEN_ROLE roles are available."
        );

        (
            bool _isMktAdvRole,
            bool _isTeamRole,
            bool _isAirdropRole,
            bool _isCuyTokenRole
        ) = _whichRoleIs(_typeOfAccount);

        // verify enough funds for allocation
        uint256 _fundsAllocated;
        uint256 _fundsForAllocation;
        uint256 _vestingPeriods = vestingPeriods;

        if (_isMktAdvRole) {
            _fundsAllocated = fundsAllocated.mktAndAdvisors;
            _fundsForAllocation = fundsForAllocation.mktAndAdvisors;
        } else if (_isTeamRole) {
            _fundsAllocated = fundsAllocated.team;
            _fundsForAllocation = fundsForAllocation.team;
        } else if (_isAirdropRole) {
            _fundsAllocated = fundsAllocated.airdrop;
            _fundsForAllocation = fundsForAllocation.airdrop;
            _vestingPeriods = 4; // 25% -> 4 periods in total
        } else if (_isCuyTokenRole) {
            _fundsAllocated = fundsAllocated.cuyToken;
            _fundsForAllocation = fundsForAllocation.cuyToken;
            _vestingPeriods = 4; // 25% -> 4 periods in total
        } else {
            revert("Vesting: A role has not been validated.");
        }

        require(
            _fundsAllocated.add(_fundsToVest) <= _fundsForAllocation,
            "Vesting: Not enough funds to allocate for vesting."
        );

        // creates Vesting
        uint256[] memory _datesForVesting = new uint256[](_vestingPeriods);
        uint128 ix = 0;
        uint256 _time = block.timestamp;
        while (ix < _vestingPeriods) {
            _time += (30 days) * gapBetweenVestingPeriods;
            _datesForVesting[ix] = _time;
            ix++;
        }

        vestingAccounts[_account] = VestingPerAccount(
            true,
            _fundsToVest,
            0,
            0,
            _datesForVesting,
            _typeOfAccount
        );

        // updates funds
        if (_isMktAdvRole) {
            fundsAllocated.mktAndAdvisors += _fundsToVest;
        } else if (_isTeamRole) {
            fundsAllocated.team += _fundsToVest;
        } else if (_isAirdropRole) {
            fundsAllocated.airdrop += _fundsToVest;
        } else if (_isCuyTokenRole) {
            fundsAllocated.cuyToken += _fundsToVest;
        } else {
            revert("Vesting: A role has not been validated.");
        }
    }

    function removesVestingSchemaForAccount(address _account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        // verify that account is vesting
        require(
            !vestingAccounts[_account].isVesting,
            "Vesting: This account does not have a vesting schema."
        );

        VestingPerAccount memory vestingAcc = vestingAccounts[_account];

        require(
            _isAValidRole(vestingAcc.typeOfAccount),
            "Vesting: Only MARKETING_ADV_ROLE, TEAM_ROLE, CUYTOKEN_ROLE and AIRDROP_ROLE roles could be removed."
        );

        uint256 _totalFundsToUpdate = vestingAcc.fundsToVestForThisAccount.sub(
            vestingAcc.totalFundsVested
        );

        (
            bool _isMktAdvRole,
            bool _isTeamRole,
            bool _isAirdropRole,
            bool _isCuyTokenRole
        ) = _whichRoleIs(vestingAcc.typeOfAccount);

        if (_isMktAdvRole) {
            fundsAllocated.mktAndAdvisors -= _totalFundsToUpdate;
        } else if (_isTeamRole) {
            fundsAllocated.team -= _totalFundsToUpdate;
        } else if (_isAirdropRole) {
            fundsAllocated.airdrop -= _totalFundsToUpdate;
        } else if (_isCuyTokenRole) {
            fundsAllocated.cuyToken -= _totalFundsToUpdate;
        } else {
            revert("Vesting: A role has not been validated.");
        }

        vestingAccounts[_account] = VestingPerAccount(
            false,
            0,
            0,
            0,
            new uint256[](0),
            ""
        );
    }

    function claimTokensWithVesting() public whenNotPaused nonReentrant {
        // verify that account is vesting
        require(
            vestingAccounts[_msgSender()].isVesting,
            "Vesting: This account does not have a vesting schema."
        );

        VestingPerAccount memory vestingAcc = vestingAccounts[_msgSender()];
        require(
            _isAValidRole(vestingAcc.typeOfAccount),
            "Vesting: Only MARKETING_ADV_ROLE, TEAM_ROLE, CUYTOKEN_ROLE and AIRDROP_ROLE roles could be removed."
        );

        uint256 _currVestingPeriod = vestingAcc.currentVestingPeriod;
        uint256 _currentDateOfVesting = vestingAcc.datesForVesting[
            _currVestingPeriod
        ];
        uint256 _todayClaimTime = block.timestamp;
        require(
            _todayClaimTime > _currentDateOfVesting,
            "Vesting: You already claimed tokens for the current vesting period."
        );
        require(
            _currVestingPeriod < vestingPeriods,
            "Vesting: All tokens for vesting have been claimed."
        );

        uint256 _deltaIndex = _todayClaimTime.sub(_currentDateOfVesting).div(
            30 days
        );

        uint256 _fundsToTransfer = vestingAcc
            .fundsToVestForThisAccount
            .div(vestingPeriods)
            .mul(_deltaIndex + 1);

        pachaCuyToken.safeTransfer(_msgSender(), _fundsToTransfer);

        vestingAccounts[_msgSender()].currentVestingPeriod += (_deltaIndex + 1);
        vestingAccounts[_msgSender()].totalFundsVested += _fundsToTransfer;
    }

    //////////////////////////////////////////////////////////////////////////
    /////////////////////////// Voting Process ///////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    function createVotingProposal(string memory _votingProposalDescription)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes32)
    {
        bytes32 hashId = keccak256(
            abi.encodePacked(
                block.timestamp,
                _msgSender(),
                _votingProposalDescription
            )
        );
        proposals[hashId] = VotingProposal(
            hashId,
            _votingProposalDescription,
            block.timestamp,
            1 days,
            new address[](0),
            new address[](0),
            false
        );
        hashIdOfProposalsList.push(hashId);

        emit VotingProposalCreated(
            _msgSender(),
            hashId,
            _votingProposalDescription,
            block.timestamp,
            block.timestamp.add(1 days)
        );

        return hashId;
    }

    function vote(bytes32 _hashId, bool aFavor) external {
        require(
            pachaCuyToken.balanceOf(_msgSender()) > 0,
            "Vesting: Votante no tiene balance de monedas Pachacuy."
        );

        require(
            !hasVotedList[_hashId][_msgSender()],
            "Vesting: Votante ya ha emitido su voto para esta propuesta."
        );

        VotingProposal storage votingProposal = proposals[_hashId];
        require(
            block.timestamp <=
                votingProposal.creationDate.add(votingProposal.duration),
            "Vesting: El tiempo de votacion ya ha terminado."
        );

        if (aFavor) {
            votingProposal.votersInFavor.push(_msgSender());
        } else {
            votingProposal.votersAgainst.push(_msgSender());
        }
        hasVotedList[_hashId][_msgSender()] = true;

        emit Vote(
            _msgSender(),
            _hashId,
            votingProposal.votingProposalDescription,
            aFavor
        );
    }

    function computeVotes(bytes32 _hashId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        VotingProposal storage votingProposal = proposals[_hashId];
        require(
            block.timestamp >=
                votingProposal.creationDate.add(votingProposal.duration),
            "Vesting: El tiempo de votacion aun no ha terminado."
        );

        if (
            votingProposal.votersInFavor.length >
            votingProposal.votersAgainst.length
        ) {
            votingProposal.approved = true;
        } else {
            votingProposal.approved = false;
        }

        emit ProposalDecision(
            _hashId,
            votingProposal.votingProposalDescription,
            votingProposal.approved,
            votingProposal.votersInFavor.length,
            votingProposal.votersAgainst.length
        );
    }

    function consultVotingProposal(bytes32 _hashId)
        external
        view
        returns (
            bytes32 hashId,
            string memory description,
            uint256 creationDate,
            uint256 duration,
            address[] memory votersInFavor,
            address[] memory votersAgainst,
            uint256 totalVotesInFavor,
            uint256 totalVotesAgainst,
            bool approved
        )
    {
        hashId = proposals[_hashId].hashId;
        description = proposals[_hashId].votingProposalDescription;
        creationDate = proposals[_hashId].creationDate;
        duration = proposals[_hashId].duration;
        votersInFavor = proposals[_hashId].votersInFavor;
        votersAgainst = proposals[_hashId].votersAgainst;
        totalVotesInFavor = proposals[_hashId].votersInFavor.length;
        totalVotesAgainst = proposals[_hashId].votersAgainst.length;
        approved = proposals[_hashId].approved;
    }

    function getListOfProposals() public view returns (bytes32[] memory) {
        return hashIdOfProposalsList;
    }

    //////////////////////////////////////////////////////////////////////////
    /////////////////////////// Auxiliar Function ////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    function _bytes32(string memory _typeOfAccount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_typeOfAccount));
    }

    function _isAValidRole(string memory _typeOfAccount)
        internal
        pure
        returns (bool)
    {
        return
            _bytes32(_typeOfAccount) == MARKETING_ADV_ROLE ||
            _bytes32(_typeOfAccount) == TEAM_ROLE ||
            _bytes32(_typeOfAccount) == CUYTOKEN_ROLE ||
            _bytes32(_typeOfAccount) == AIRDROP_ROLE;
    }

    function _whichRoleIs(string memory _typeOfAccount)
        internal
        pure
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        return (
            _bytes32(_typeOfAccount) == MARKETING_ADV_ROLE,
            _bytes32(_typeOfAccount) == TEAM_ROLE,
            _bytes32(_typeOfAccount) == AIRDROP_ROLE,
            _bytes32(_typeOfAccount) == CUYTOKEN_ROLE
        );
    }

    function setPachaCuyAddress(address _pachaCuyToken)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken = IERC20Upgradeable(_pachaCuyToken);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function getDecimals() internal pure returns (uint256) {
        return 18;
    }

    function million() internal pure returns (uint256) {
        return 10**6;
    }

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
}
