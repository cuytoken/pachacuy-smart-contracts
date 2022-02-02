// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../random/IRandomGenerator.sol";

/// @custom:security-contact lee@cuytoken.com
contract Airdrop is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    // Managing contracts
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // airdrop
    mapping(address => uint256) airdropReceivedPerAccount;
    mapping(address => uint256) randomAirdropWinners;
    event AirdropDelivered(address _account, uint256 _amount);
    event RandomAirdropRequested(address _account);
    event RandomAirdropDelivered(
        address _account,
        uint256 _prize,
        uint256 _delivered
    );
    uint256 public randomAirdropDelivered;
    uint256 public randomAirdropCap;

    //address of Random Number Generator contract
    IRandomGenerator private rngService;

    // pachacuy token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable pachaCuyToken;

    using SafeMathUpgradeable for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @notice Sends airdrop tokens in batches.
     * @param _addresses: list of accounts to received airdrop tokens
     */
    function sendAirdropBatch(
        address[] memory _addresses,
        uint256[] memory _amounts
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        uint256 _amountToAirdrop;
        for (uint256 iy = 0; iy < _amounts.length; iy++) {
            _amountToAirdrop += _amounts[iy];
        }
        require(
            pachaCuyToken.balanceOf(address(this)) >= _amountToAirdrop,
            "Airdrop: Not enough Pacha Cuy balance for airdrop."
        );

        for (uint256 ix = 0; ix < _addresses.length; ix++) {
            address _account = _addresses[ix];
            uint256 _amount = _amounts[ix];
            pachaCuyToken.safeTransfer(_account, _amount);
            airdropReceivedPerAccount[_account] += _amount;
            emit AirdropDelivered(_account, _amount);
        }
    }

    function participateRandomAirdrop500() external {
        require(
            randomAirdropWinners[_msgSender()] == 0,
            "Airdrop: This account already participated in the Random Airdrop 500."
        );

        require(
            rngService.isRequestComplete(_msgSender()),
            "Airdrop: Your Airdrop giveaway is being processed."
        );

        require(
            pachaCuyToken.balanceOf(address(this)) >= 500,
            "Airdrop: Balance for Airdrop is not enough."
        );

        require(
            randomAirdropCap - randomAirdropDelivered >= 500,
            "Airdrop: Not enough balance for random airdrop"
        );

        requestRandomAirdrop(_msgSender());
        emit RandomAirdropRequested(_msgSender());
    }

    function requestRandomAirdrop(address _account) internal {
        rngService.requestRandomNumber(_account);
    }

    // Callback called by RandomGenerator contract
    function fulfillRandomness(address _account, uint256 randomness) external {
        require(
            address(rngService) == _msgSender(),
            "This function can be called only by the Random Number Generator!"
        );

        uint256 _prize = randomness.mod(500).add(1).mul(10**18);
        randomAirdropWinners[_account] += _prize;
        randomAirdropDelivered += _prize;
        pachaCuyToken.safeTransfer(_account, _prize);

        emit RandomAirdropDelivered(_account, _prize, randomAirdropDelivered);
    }

    function setPachaCuyAddress(address _pachaCuyToken)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken = IERC20Upgradeable(_pachaCuyToken);
    }

    /**
     * @notice used to change the address of the Random Number Generator contract
     * @param _rngAddress new address of the Random Number Generator contract
     */
    function setRngAddress(address _rngAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _rngAddress != address(0),
            "Vault Manager: Random Number Generator contract address cannot be address 0!"
        );
        rngService = IRandomGenerator(_rngAddress);
    }

    /**
     * @notice used to set the cap for the random prize airdrop
     * @param _cap upper limit for random prize aidrop
     */
    function setCapForRandomAirdrop(uint256 _cap)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        randomAirdropCap = _cap;
    }

    /**
     * @notice Pauses the contract
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
