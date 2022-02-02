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

    using SafeMathUpgradeable for uint256;

    // vesting
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
    }

    // Funds for allocation - cap
    Funds fundsForAllocation;
    // Funds effectively allocated
    Funds fundsAllocated;

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

    // Each person vesting info
    struct VestingPerAccount {
        bool isVesting;
        uint256 fundsToVestForThisAccount;
        uint256 currentVestingPeriod;
        uint256 totalFundsVested;
        uint256[] datesForVesting;
        bytes32 typeOfAccount;
    }

    function settingVestingStateStructs() private {
        // Total funds for allocation
        fundsForAllocation = Funds(
            10 * million() * 10**getDecimals(),
            7 * million() * 10**getDecimals()
        );

        // Funds effectively allocated
        fundsAllocated = Funds(0, 0);
    }

    function createVestingSchemaForAccount(
        address _account,
        uint256 _fundsToVestForThisAccount,
        string memory _typeOfAccount //
    ) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        // verify that account is not vesting
        require(
            !vestingAccounts[_account].isVesting,
            "Vesting: This account already has a vesting schema."
        );

        // verify roles
        require(
            isMarketingRole(_typeOfAccount) || isTeamRole(_typeOfAccount),
            "Vesting: Only MARKETING_ADV_ROLE and TEAM_ROLE roles are available."
        );

        // verify enough funds for allocation
        uint256 _fundsAllocated = isMarketingRole(_typeOfAccount)
            ? fundsAllocated.mktAndAdvisors
            : fundsAllocated.team;
        uint256 _fundsForAllocation = isMarketingRole(_typeOfAccount)
            ? fundsForAllocation.mktAndAdvisors
            : fundsForAllocation.team;

        require(
            (_fundsAllocated + _fundsToVestForThisAccount) <=
                _fundsForAllocation,
            "Vesting: Not enough funds to allocate for vesting."
        );

        uint256[] memory _datesForVesting = new uint256[](vestingPeriods);
        uint128 ix = 0;
        uint256 _time = block.timestamp;
        while (ix < vestingPeriods) {
            _time += (30 days) * gapBetweenVestingPeriods;
            _datesForVesting[ix] = _time;
            ix++;
        }

        vestingAccounts[_account] = VestingPerAccount(
            true,
            _fundsToVestForThisAccount,
            0,
            0,
            _datesForVesting,
            keccak256(abi.encodePacked(_typeOfAccount))
        );

        if (isMarketingRole(_typeOfAccount)) {
            fundsAllocated.mktAndAdvisors += _fundsToVestForThisAccount;
        } else {
            fundsAllocated.team += _fundsToVestForThisAccount;
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

        bytes32 _typeOfAccount = vestingAcc.typeOfAccount;
        require(
            _typeOfAccount == MARKETING_ADV_ROLE || _typeOfAccount == TEAM_ROLE,
            "Vesting: Only MARKETING_ADV_ROLE and TEAM_ROLE roles could be removed."
        );

        uint256 _totalFundsToUpdate = vestingAcc.fundsToVestForThisAccount -
            vestingAcc.totalFundsVested;

        if (_typeOfAccount == MARKETING_ADV_ROLE) {
            fundsAllocated.mktAndAdvisors -= _totalFundsToUpdate;
        } else if (_typeOfAccount == TEAM_ROLE) {
            fundsAllocated.team -= _totalFundsToUpdate;
        }

        vestingAccounts[_account] = VestingPerAccount(
            false,
            0,
            0,
            0,
            new uint256[](vestingPeriods),
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
        bytes32 _typeOfAccount = vestingAcc.typeOfAccount;
        require(
            _typeOfAccount == MARKETING_ADV_ROLE || _typeOfAccount == TEAM_ROLE,
            "Vesting: Only MARKETING_ADV_ROLE and TEAM_ROLE roles could be removed."
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
        // implement safe math
        uint256 _deltaIndex = _todayClaimTime.sub(_currentDateOfVesting).div(
            30 days
        );

        uint256 _fundsToTransfer = vestingAcc
            .fundsToVestForThisAccount
            .div(vestingPeriods)
            .mul(_deltaIndex + 1);

        pachaCuyToken.transfer(_msgSender(), _fundsToTransfer);

        vestingAccounts[_msgSender()].currentVestingPeriod += (_deltaIndex + 1);
        vestingAccounts[_msgSender()].totalFundsVested += _fundsToTransfer;
    }

    function isMarketingRole(string memory _typeOfAccount)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_typeOfAccount)) == MARKETING_ADV_ROLE;
    }

    function isTeamRole(string memory _typeOfAccount)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(_typeOfAccount)) == TEAM_ROLE;
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
        return 8;
    }

    function million() internal pure returns (uint256) {
        return 10**6;
    }
}
