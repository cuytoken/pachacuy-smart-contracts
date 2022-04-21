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
////                                              Vesting Controller                                             ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract Vesting is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    IERC777RecipientUpgradeable,
    UUPSUpgradeable
{
    /**
     * ROLES FOR VESTING       Q     Vest %
     * -----
     * HOLDER_CUY_TOKEN     -> 1    -> 25%
     * PRIVATE_SALE_1       -> 1.5  -> 25%
     * PRIVATE_SALE_2       -> 0.6  -> 25%
     * AIRDROP              -> 1.2  -> 25%
     * PACHACUY_TEAM        -> 12   -> 10%
     * PARTNER_ADVISOR      -> 10   -> 10%
     * MARKETING            -> 10   -> 10%
     * ------------------------------------
     * TOTAL                -> 36.3
     */

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MANAGER_VESTING = keccak256("MANAGER_VESTING");

    using SafeMathUpgradeable for uint256;

    // expressed in months
    uint128 gapBetweenVestingPeriods;

    // Inidividual Vesting info
    struct VestingPerAccount {
        bool isVesting;
        uint256 fundsToVestForThisAccount;
        uint256 currentVestingPeriod;
        uint256 totalFundsVested;
        uint256[] datesForVesting;
        string _roleOfAccount;
    }
    mapping(string => mapping(address => VestingPerAccount)) vestingAccounts;

    // pachacuy token
    IERC777Upgradeable pachaCuyToken;

    // vesting funds for all roles
    struct Fund {
        string role;
        uint256 fundsForAllocation;
        uint256 fundsAllocated;
        uint256 percentage;
        address[] addresses;
        uint256 releaseDay;
    }
    // Role => Fund
    mapping(string => Fund) fundsMapping;

    // All Roles
    string[] roles = new string[](0);

    event TokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        uint128 _gapBetweenVestingPeriods,
        string[] memory fundsRole,
        uint256[] memory fundsCap,
        uint256[] memory fundsPercentages,
        uint256[] memory releaseDayArray
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(MANAGER_VESTING, _msgSender());

        gapBetweenVestingPeriods = _gapBetweenVestingPeriods;

        settingVestingStateStructs(
            fundsRole,
            fundsCap,
            fundsPercentages,
            releaseDayArray
        );
    }

    //////////////////////////////////////////////////////////////////////////
    /////////////////////////// Vesting Process //////////////////////////////
    //////////////////////////////////////////////////////////////////////////
    function settingVestingStateStructs(
        string[] memory fundsRole,
        uint256[] memory fundsCap,
        uint256[] memory fundsPercentages,
        uint256[] memory releaseDayArray
    ) private {
        uint256 l = fundsRole.length;
        for (uint256 i = 0; i < l; ++i) {
            fundsMapping[fundsRole[i]] = Fund({
                role: fundsRole[i],
                fundsForAllocation: fundsCap[i],
                fundsAllocated: 0,
                percentage: fundsPercentages[i],
                addresses: new address[](0),
                releaseDay: releaseDayArray[i]
            });
            roles.push(fundsRole[i]);
        }
    }

    function createVestingSchema(
        address _account,
        uint256 _fundsToVest,
        string memory _roleOfAccount
    ) public whenNotPaused onlyRole(MANAGER_VESTING) {
        // verify that account is not vesting
        require(
            !vestingAccounts[_roleOfAccount][_account].isVesting,
            "Vesting: Account for that role has a vesting schema."
        );

        // verify roles
        require(_isAValidRole(_roleOfAccount), "Vesting: Not a valid role.");

        // verify enough funds for allocation
        uint256 _fundsAllocated = fundsMapping[_roleOfAccount].fundsAllocated;
        uint256 _fundsForAllocation = fundsMapping[_roleOfAccount]
            .fundsForAllocation;
        uint256 _vestingPeriods = 100 / fundsMapping[_roleOfAccount].percentage;

        require(
            _fundsAllocated.add(_fundsToVest) <= _fundsForAllocation,
            "Vesting: Not enough funds to allocate for vesting."
        );

        // creates Vesting
        uint256[] memory _datesForVesting = new uint256[](_vestingPeriods);
        uint128 ix = 0;
        uint256 _time = fundsMapping[_roleOfAccount].releaseDay;
        while (ix < _vestingPeriods) {
            _time += (30 days) * gapBetweenVestingPeriods;
            _datesForVesting[ix] = _time;
            ix++;
        }

        vestingAccounts[_roleOfAccount][_account] = VestingPerAccount(
            true,
            _fundsToVest,
            0,
            0,
            _datesForVesting,
            _roleOfAccount
        );

        // updates funds
        fundsMapping[_roleOfAccount].fundsAllocated += _fundsToVest;

        // add account to array
        fundsMapping[_roleOfAccount].addresses.push(_account);
    }

    function createVestingSchemaBatch(
        address[] memory _accounts,
        uint256[] memory _fundsToVestArray,
        string[] memory _roleOfAccounts
    ) public whenNotPaused onlyRole(MANAGER_VESTING) {
        uint256 l = _accounts.length;
        require(
            l == _fundsToVestArray.length &&
                _fundsToVestArray.length == _roleOfAccounts.length,
            "Vesting: Arrays must have same length."
        );
        for (uint256 i = 0; i < l; ++i) {
            createVestingSchema(
                _accounts[i],
                _fundsToVestArray[i],
                _roleOfAccounts[i]
            );
        }
    }

    function removesVestingSchemaForAccount(
        address _account,
        string memory _roleOfAccount
    ) public onlyRole(MANAGER_VESTING) whenNotPaused {
        // verify that account is vesting
        require(
            vestingAccounts[_roleOfAccount][_account].isVesting,
            "Vesting: This account does not have a vesting schema."
        );

        require(_isAValidRole(_roleOfAccount), "Vesting: Not a valid role.");

        VestingPerAccount memory vestingAcc = vestingAccounts[_roleOfAccount][
            _account
        ];

        uint256 _totalFundsToUpdate = vestingAcc.fundsToVestForThisAccount.sub(
            vestingAcc.totalFundsVested
        );

        fundsMapping[_roleOfAccount].fundsAllocated -= _totalFundsToUpdate;

        delete vestingAccounts[_roleOfAccount][_account];

        // remove account from array fundsMapping
        _rmvFromFundsMapping(_roleOfAccount, _account);
    }

    function _rmvFromFundsMapping(string memory _role, address _account)
        private
    {
        uint256 l = fundsMapping[_role].addresses.length;
        address[] memory addresses = fundsMapping[_role].addresses;
        uint256 ix = 0;
        while (ix < l) {
            if (addresses[ix] == _account) break;
            ix++;
        }

        // remove the element
        fundsMapping[_role].addresses[ix] = fundsMapping[_role].addresses[
            fundsMapping[_role].addresses.length - 1
        ];
        fundsMapping[_role].addresses.pop();
    }

    function claimTokensWithVesting() public whenNotPaused nonReentrant {
        uint256 l = roles.length;
        bool isVesting = false;
        for (uint256 i = 0; i < l; ++i) {
            if (vestingAccounts[roles[i]][_msgSender()].isVesting) {
                // verify if account is vesting for any role
                isVesting = true;

                // vesting periods
                uint256 _vestingPeriods = 100 /
                    fundsMapping[roles[i]].percentage;

                VestingPerAccount memory vestingAcc = vestingAccounts[roles[i]][
                    _msgSender()
                ];

                uint256 _currVestingPeriod = vestingAcc.currentVestingPeriod;
                uint256 _currentDateOfVesting = vestingAcc.datesForVesting[
                    _currVestingPeriod
                ];
                uint256 _todayClaimTime = block.timestamp;

                // "Vesting: You already claimed tokens for the current vesting period."
                if (_todayClaimTime > _currentDateOfVesting) continue;

                // "Vesting: All tokens for vesting have been claimed."
                if (_currVestingPeriod < _vestingPeriods) continue;

                uint256 _deltaIndex = _todayClaimTime
                    .sub(_currentDateOfVesting)
                    .div(30 days);

                uint256 _fundsToTransfer = vestingAcc
                    .fundsToVestForThisAccount
                    .div(_vestingPeriods)
                    .mul(_deltaIndex + 1);

                pachaCuyToken.send(
                    _msgSender(),
                    _fundsToTransfer,
                    bytes("Vesting")
                );

                vestingAccounts[roles[i]][_msgSender()]
                    .currentVestingPeriod += (_deltaIndex + 1);
                vestingAccounts[roles[i]][_msgSender()]
                    .totalFundsVested += _fundsToTransfer;
            }
        }
        require(isVesting, "Vesting: Account is not vesting for any role");
    }

    //////////////////////////////////////////////////////////////////////////
    /////////////////////////// Auxiliar Function ////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    function _bytes32(string memory _roleOfAccount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_roleOfAccount));
    }

    function _isAValidRole(string memory _roleOfAccount)
        internal
        pure
        returns (bool)
    {
        return
            _bytes32(_roleOfAccount) == keccak256("HOLDER_CUY_TOKEN") ||
            _bytes32(_roleOfAccount) == keccak256("PRIVATE_SALE_1") ||
            _bytes32(_roleOfAccount) == keccak256("PRIVATE_SALE_2") ||
            _bytes32(_roleOfAccount) == keccak256("PACHACUY_TEAM") ||
            _bytes32(_roleOfAccount) == keccak256("PARTNER_ADVISOR") ||
            _bytes32(_roleOfAccount) == keccak256("MARKETING") ||
            _bytes32(_roleOfAccount) == keccak256("AIRDROP");
    }

    function setPachaCuyAddress(address _pachaCuyToken)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken = IERC777Upgradeable(_pachaCuyToken);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensReceived(operator, from, to, amount, userData, operatorData);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
}
