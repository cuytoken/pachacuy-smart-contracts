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

import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777SenderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC1820RegistryUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract Vesting is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    IERC777RecipientUpgradeable,
    IERC777SenderUpgradeable,
    UUPSUpgradeable
{
    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY =
        IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    /**
     * ROLES FOR VESTING       Q
     * -----
     * HOLDER_CUY_TOKEN     -> 1
     * PRIVATE_SALE_1       -> 1.5
     * PRIVATE_SALE_2       -> 0.6
     * AIRDROP              -> 1.2
     * PACHACUY_TEAM        -> 12
     * PARTNER_ADVISOR      -> 10
     * MARKETING            -> 10
     * ------------------------------------
     * TOTAL                -> 36.3
     */

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MANAGER_VESTING = keccak256("MANAGER_VESTING");

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    using SafeMathUpgradeable for uint256;

    // Inidividual Vesting info
    struct VestingPerAccount {
        uint256 fundsToVestForThisAccount;
        uint256 currentVestingPeriod;
        uint256 totalFundsVested;
        uint256[] datesForVesting;
        string roleOfAccount;
        uint256 uuid;
        uint256 vestingPeriods;
    }
    mapping(address => VestingPerAccount[]) vestingAccounts;

    // pachacuy token
    IERC777Upgradeable pachaCuyToken;

    // vesting funds for all roles
    /**
     * @param role The role of the account
     * @param fundsForAllocation Total funds to allocate for this role
     * @param fundsAllocated Funds already allocated for this role
     */
    struct Fund {
        string role;
        uint256 fundsForAllocation;
        uint256 fundsAllocated;
    }
    // Role => Fund
    mapping(string => Fund) fundsMapping;

    event TokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    event TokensSent(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(MANAGER_VESTING, _msgSender());

        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_SENDER_INTERFACE_HASH,
            address(this)
        );
    }

    //////////////////////////////////////////////////////////////////////////
    /////////////////////////// Vesting Process //////////////////////////////
    //////////////////////////////////////////////////////////////////////////
    function settingVestingStateStructs(
        string[] memory fundsRole,
        uint256[] memory fundsCap
    ) external onlyRole(MANAGER_VESTING) {
        uint256 l = fundsRole.length;
        for (uint256 i = 0; i < l; ++i) {
            fundsMapping[fundsRole[i]] = Fund({
                role: fundsRole[i],
                fundsForAllocation: fundsCap[i],
                fundsAllocated: 0
            });
        }
    }

    /**
     * @param _account wallet address of the account to be vested
     * @param _fundsToVest amount of tokens to be vested
     * @param _vestingPeriods amount of months to vest for
     * @param _releaseDay role of the account to be vested
     * @param _roleOfAccount role of the account to be vested
     */
    function createVestingSchema(
        address _account,
        uint256 _fundsToVest,
        uint256 _vestingPeriods,
        uint256 _releaseDay,
        string memory _roleOfAccount
    ) public whenNotPaused onlyRole(MANAGER_VESTING) {
        // verify roles
        require(_isAValidRole(_roleOfAccount), "Vesting: Not a valid role.");

        // verify enough funds for allocation
        uint256 _fundsAllocated = fundsMapping[_roleOfAccount].fundsAllocated;
        uint256 _fundsForAllocation = fundsMapping[_roleOfAccount]
            .fundsForAllocation;

        require(
            _fundsAllocated.add(_fundsToVest) <= _fundsForAllocation,
            "Vesting: Not enough funds to allocate for vesting."
        );

        // creates Vesting
        uint256[] memory _datesForVesting = new uint256[](_vestingPeriods);
        uint128 ix = 0;
        uint256 _time = _releaseDay;
        while (ix < _vestingPeriods) {
            _time += (30 days);
            _datesForVesting[ix] = _time;
            ix++;
        }

        VestingPerAccount[] storage _vestingArray = vestingAccounts[_account];

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _vestingArray.push(
            VestingPerAccount({
                fundsToVestForThisAccount: _fundsToVest,
                currentVestingPeriod: 0,
                totalFundsVested: 0,
                datesForVesting: _datesForVesting,
                roleOfAccount: _roleOfAccount,
                uuid: current,
                vestingPeriods: _vestingPeriods
            })
        );

        // updates funds
        fundsMapping[_roleOfAccount].fundsAllocated += _fundsToVest;
    }

    function createVestingSchemaBatch(
        address[] memory _accounts,
        uint256[] memory _fundsToVestArray,
        uint256[] memory _vestingPeriods,
        uint256[] memory _releaseDays,
        string[] memory _roleOfAccounts
    ) public whenNotPaused onlyRole(MANAGER_VESTING) {
        uint256 l = _accounts.length;
        for (uint256 i = 0; i < l; ++i) {
            createVestingSchema(
                _accounts[i],
                _fundsToVestArray[i],
                _vestingPeriods[i],
                _releaseDays[i],
                _roleOfAccounts[i]
            );
        }
    }

    function removesVestingSchemaForAccount(address _account, uint256 _uuid)
        public
        onlyRole(MANAGER_VESTING)
        whenNotPaused
    {
        VestingPerAccount[] storage _vestingArray = vestingAccounts[_account];

        // verify that account is vesting
        uint256 l = _vestingArray.length;
        bool found = false;
        uint256 x;
        for (x = 0; x < l; x++) {
            if (_vestingArray[x].uuid == _uuid) {
                found = true;
                break;
            }
        }
        require(found, "Vesting: Account is not vesting.");

        // update funds for vesting role
        VestingPerAccount memory vestingAcc = _vestingArray[x];
        uint256 _totalFundsToUpdate = vestingAcc.fundsToVestForThisAccount.sub(
            vestingAcc.totalFundsVested
        );
        fundsMapping[vestingAcc.roleOfAccount]
            .fundsAllocated -= _totalFundsToUpdate;

        // removing vesting schema from vesting array
        _vestingArray[x] = _vestingArray[l - 1];
        _vestingArray.pop();
    }

    function claimTokensWithVesting(uint256 _uuid) public whenNotPaused {
        VestingPerAccount[] storage _vestingArray = vestingAccounts[
            _msgSender()
        ];

        // verify that account is vesting
        uint256 l = _vestingArray.length;
        bool found = false;
        uint256 x;
        for (x = 0; x < l; x++) {
            if (_vestingArray[x].uuid == _uuid) {
                found = true;
                break;
            }
        }
        require(found, "Vesting: Account is not vesting.");

        VestingPerAccount storage vestingAcc = _vestingArray[x];
        uint256 _vestingPeriods = vestingAcc.vestingPeriods;
        uint256 _currVestingPeriod = vestingAcc.currentVestingPeriod;
        uint256 _currentDateOfVesting = vestingAcc.datesForVesting[
            _currVestingPeriod
        ];
        uint256 _todayClaimTime = block.timestamp;

        require(
            _todayClaimTime > _currentDateOfVesting,
            "Vesting: You already claimed tokens for the current vesting period"
        );

        require(
            _currVestingPeriod < _vestingPeriods,
            "Vesting: All tokens for vesting have been claimed"
        );

        uint256 _deltaIndex = _todayClaimTime.sub(_currentDateOfVesting).div(
            30 days
        );

        uint256 _fundsToTransfer = vestingAcc
            .fundsToVestForThisAccount
            .div(_vestingPeriods)
            .mul(_deltaIndex + 1);

        pachaCuyToken.send(_msgSender(), _fundsToTransfer, bytes("Vesting"));

        vestingAcc.currentVestingPeriod += (_deltaIndex + 1);
        vestingAcc.totalFundsVested += _fundsToTransfer;
    }

    //////////////////////////////////////////////////////////////////////////
    ///////////////////////////  Helper Function  ////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    function getArrayVestingSchema(address _acccount)
        external
        view
        returns (VestingPerAccount[] memory _arrayVesting)
    {
        _arrayVesting = vestingAccounts[_acccount];
    }

    function getVestingSchemaWithUuid(address _account, uint256 _uuid)
        external
        view
        returns (
            uint256 fundsToVestForThisAccount,
            uint256 currentVestingPeriod,
            uint256 totalFundsVested,
            uint256[] memory datesForVesting,
            string memory roleOfAccount,
            uint256 uuid,
            uint256 vestingPeriods
        )
    {
        VestingPerAccount[] memory _vestingArray = vestingAccounts[_account];

        // verify that account is vesting
        uint256 l = _vestingArray.length;
        bool found = false;
        uint256 x;
        for (x = 0; x < l; x++) {
            if (_vestingArray[x].uuid == _uuid) {
                found = true;
                break;
            }
        }
        require(found, "Vesting: Account is not vesting.");

        VestingPerAccount memory vestingAcc = _vestingArray[x];
        fundsToVestForThisAccount = vestingAcc.fundsToVestForThisAccount;
        currentVestingPeriod = vestingAcc.currentVestingPeriod;
        totalFundsVested = vestingAcc.totalFundsVested;
        datesForVesting = vestingAcc.datesForVesting;
        roleOfAccount = vestingAcc.roleOfAccount;
        uuid = vestingAcc.uuid;
        vestingPeriods = vestingAcc.vestingPeriods;
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

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensSent(operator, from, to, amount, userData, operatorData);
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
