// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @custom:security-contact lee@cuytoken.com
contract Vesting is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    // Managing contracts
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BACKEND_ADMIN = keccak256("BACKEND_ADMIN");

    // Vesting Roles
    bytes32 public constant MARKETING_ADV_ROLE =
        keccak256("MARKETING_ADV_ROLE");
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    // vesting
    uint128 vestingPeriods;
    uint128 gapBetweenVestingPeriods; // expressed in months
    mapping(address => VestingPerAccount) vestingAccounts;

    // pachacuy token
    ERC20Upgradeable pachaCuyToken;

    struct FundsAllocation {
        uint256 privateSale;
        uint256 cuytokenExchange;
        uint256 publicSale;
        uint256 team;
        uint256 mktAndAdvisors;
        uint256 airDrop;
        uint256 liquidityPool;
        uint256 gameRewards;
        uint256 phaseTwo;
        uint256 phaseX;
    }

    // Funds allocated
    FundsAllocation fundsAllocationFinal;
    // Funds effectively allocated
    FundsAllocation fundsEffectivelyAllocated;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function getDecimals() internal pure returns (uint256) {
        return 10**18;
    }

    function initialize(
        uint128 _vestingPeriods,
        uint128 _gapBetweenVestingPeriods,
        address _pachaCuyAddress
    ) public initializer {
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        // vesting
        vestingPeriods = _vestingPeriods;
        gapBetweenVestingPeriods = _gapBetweenVestingPeriods;
        pachaCuyToken = ERC20Upgradeable(_pachaCuyAddress);
        settingVestingStateStructs();
    }

    struct VestingPerAccount {
        uint256 totalFundsForVesting;
        uint256 currentVestingPeriod;
        uint256 totalFundsClaimed;
        uint256[] datesForVesting;
        bytes32 typeOfAccount;
    }

    function settingVestingStateStructs() private {
        // Funds allocated
        fundsAllocationFinal = FundsAllocation(
            2 * 10**6 * getDecimals(),
            25 * 10**5 * getDecimals(),
            8 * 10**6 * getDecimals(),
            10 * 10**6 * getDecimals(),
            7 * 10**6 * getDecimals(),
            1 * 10**6 * getDecimals(),
            26 * 10**6 * getDecimals(),
            26 * 10**6 * getDecimals(),
            6 * 10**6 * getDecimals(),
            115 * 10**5 * getDecimals()
        );

        // Funds effectively allocated
        fundsEffectivelyAllocated = FundsAllocation(
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );
    }

    function createVestingSchemaForAccount(
        address _account,
        uint256 _totalFundsForVestingPerAccount,
        string memory _typeOfAccount //
    ) public onlyRole(BACKEND_ADMIN) {
        // verify roles
        require(
            keccak256(abi.encodePacked(_typeOfAccount)) == MARKETING_ADV_ROLE ||
                keccak256(abi.encodePacked(_typeOfAccount)) == TEAM_ROLE,
            "Token Admin: Only MARKETING_ADV_ROLE and TEAM_ROLE roles are available."
        );

        // verify enough funds for allocation
        uint256 fundsAllocatedForType;
        uint256 totalFundsForType;
        if (keccak256(abi.encodePacked(_typeOfAccount)) == MARKETING_ADV_ROLE) {
            fundsAllocatedForType = fundsEffectivelyAllocated.mktAndAdvisors;
            totalFundsForType = fundsAllocationFinal.mktAndAdvisors;
        } else if (keccak256(abi.encodePacked(_typeOfAccount)) == TEAM_ROLE) {
            fundsAllocatedForType = fundsEffectivelyAllocated.team;
            totalFundsForType = fundsAllocationFinal.team;
        }
        require(
            fundsAllocatedForType != 0 &&
                (fundsAllocatedForType + _totalFundsForVestingPerAccount) <=
                totalFundsForType,
            "Token Admin: Not enough balance to allocate vesting."
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
            _totalFundsForVestingPerAccount,
            0,
            0,
            _datesForVesting,
            keccak256(abi.encodePacked(_typeOfAccount))
        );

        if (keccak256(abi.encodePacked(_typeOfAccount)) == MARKETING_ADV_ROLE) {
            fundsEffectivelyAllocated
                .mktAndAdvisors += _totalFundsForVestingPerAccount;
        } else if (keccak256(abi.encodePacked(_typeOfAccount)) == TEAM_ROLE) {
            fundsEffectivelyAllocated.team += _totalFundsForVestingPerAccount;
        }
    }

    function removesVestingSchemaForAccount(address _account)
        public
        onlyRole(BACKEND_ADMIN)
    {
        VestingPerAccount memory vestingAcc = vestingAccounts[_account];

        bytes32 _typeOfAccount = vestingAcc.typeOfAccount;
        require(
            _typeOfAccount == MARKETING_ADV_ROLE || _typeOfAccount == TEAM_ROLE,
            "Token Admin: Only MARKETING_ADV_ROLE and TEAM_ROLE roles could be removed."
        );

        uint256 _totalFundsToUpdate = vestingAcc.totalFundsForVesting -
            vestingAcc.totalFundsClaimed;

        if (_typeOfAccount == MARKETING_ADV_ROLE) {
            fundsEffectivelyAllocated.mktAndAdvisors -= _totalFundsToUpdate;
        } else if (_typeOfAccount == TEAM_ROLE) {
            fundsEffectivelyAllocated.team -= _totalFundsToUpdate;
        }

        vestingAccounts[_account] = VestingPerAccount(
            0,
            0,
            0,
            new uint256[](vestingPeriods),
            ""
        );
    }

    function claimTokensWithVesting() public {
        VestingPerAccount memory vestingAcc = vestingAccounts[_msgSender()];
        bytes32 _typeOfAccount = vestingAcc.typeOfAccount;
        require(
            _typeOfAccount == MARKETING_ADV_ROLE || _typeOfAccount == TEAM_ROLE,
            "Token Admin: Only MARKETING_ADV_ROLE and TEAM_ROLE roles could be removed."
        );
        uint256 _currVestinPeriod = vestingAcc.currentVestingPeriod;
        uint256 _currentDateOfVesting = vestingAcc.datesForVesting[
            _currVestinPeriod
        ];
        uint256 _todayClaimTime = block.timestamp;
        require(
            _todayClaimTime > _currentDateOfVesting,
            "Token Admin: You already claimed tokens for the current vesting period."
        );
        require(
            _currVestinPeriod < vestingPeriods,
            "Token Admin: All tokens for vesting have been claimed."
        );
        // implement safe math
        uint256 _deltaIndex = (_todayClaimTime - _currentDateOfVesting) /
            (30 days);
        uint256 _fundsToTransfer = (vestingAcc.totalFundsForVesting /
            vestingPeriods) * _deltaIndex;

        pachaCuyToken.transfer(_msgSender(), _fundsToTransfer);

        vestingAccounts[_msgSender()].currentVestingPeriod += _deltaIndex;
        vestingAccounts[_msgSender()].totalFundsClaimed += _fundsToTransfer;
    }

    // every role will have a specific fund allocated to him
    // after a month each role will be able to withdraw a specific amount until it consumes all his fund
    // set amount of vesting periods
    // linerly claim an amount of tokens in each vesting period

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

    // periodo de vesting desde que empieza a colaborar
    // interface para intercambiar cuytokens for pacha cuy tokens
    //      solamente se puede vender el 50% de y hay un ratio en particular para intercambiar por PCUY

    // blockear 26M de tokens para el liquidity pool
    // private sale mintear 100MM
    // public sale block 8MM
    // team billetera mintear 10MM
    // marketing mintear 7MM
    // airdrop guardar billeteras a quien se les ha dado el airdrop
    //    nosotros decidimos cuando entregar el airdrop. se reparte después
    //    los usuarios pueden consultar que estan en airdrop
    //    retornar el disponible de cuanto airdrop queda
    // pool de recompensas 26MM
    // fase 2 - 6MM
    // fase x - 11.5

    // considerar que durante el vesting la persona se le puede dar de baja
}
