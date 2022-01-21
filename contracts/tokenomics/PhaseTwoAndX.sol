// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract PhaseTwoAndX is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // pachacuy token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable pachaCuyToken;

    // blocking time
    uint256 blockingTimePhaseTwo;
    uint256 blockingTimePhaseX;

    // cap funds per phase
    uint256 capLimitPhaseTwo;
    uint256 capLimitPhaseX;
    uint256 fundsPhaseTwoUsed;
    uint256 fundsPhaseXUsed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(uint256 _capLimitPhaseTwo, uint256 _capLimitPhaseX)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init();

        capLimitPhaseTwo = _capLimitPhaseTwo;
        capLimitPhaseX = _capLimitPhaseX;

        blockingTimePhaseTwo = block.timestamp + (90 days);
        blockingTimePhaseX = block.timestamp + (365 days);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function transferPhaseTwo(address _account, uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        // time has passed
        require(
            block.timestamp >= blockingTimePhaseTwo,
            "Phase2nX: Funds are still locked for this phase."
        );

        require(
            fundsPhaseTwoUsed + _amount <= capLimitPhaseTwo,
            "Phase2nX: Amount to transfer exceeds limit."
        );

        require(
            pachaCuyToken.balanceOf(address(this)) >= _amount,
            "Phase2nX: Contract does not have enough Pacha Cuy tokens."
        );

        fundsPhaseTwoUsed += _amount;
        pachaCuyToken.safeTransfer(_account, _amount);
    }

    function transferPhaseX(address _account, uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        // time has passed
        require(
            block.timestamp >= blockingTimePhaseX,
            "Phase2nX: Funds are still locked for this phase."
        );

        // enough funds
        require(
            fundsPhaseXUsed + _amount <= capLimitPhaseX,
            "Phase2nX: Amount to transfer exceeds limit."
        );

        require(
            pachaCuyToken.balanceOf(address(this)) >= _amount,
            "Phase2nX: Contract does not have enough Pacha Cuy tokens."
        );

        fundsPhaseXUsed += _amount;
        pachaCuyToken.safeTransfer(_account, _amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
