// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract Airdrop is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    // Managing contracts
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BACKEND_ADMIN = keccak256("BACKEND_ADMIN");

    // airdrop
    mapping(address => bool) isAccountInAirdrop;
    mapping(address => bool) hasAccountReceivedAirdrop;
    address[] airdropAccountList;
    uint256 public maxAmountAirdropToken;
    event EnrolledInAirdrop(address _account);
    event AirdropDelivered(address _account);

    // pachacuy token
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable pachaCuyToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _backenAddress, address _pachaCuyAddress)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init();

        pachaCuyToken = ERC20Upgradeable(_pachaCuyAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(BACKEND_ADMIN, _backenAddress);
    }

    /**
     * @notice Returns the amount of tokens left to be delivered as airdrop
     * @return amount of pachacuy tokens left as airdrop
     */
    function amountOfTokensRemainingForAirdrop() public view returns (uint256) {
        return pachaCuyToken.balanceOf(address(this));
    }

    /**
     * @notice Sets the maximun amount of tokens this smart contract will hold as airdrop tokens
     * @param _maxAmountAirdropToken: maximun amount of tokens owned by the smart contract
     */
    function setMaxAmoutAirdropToken(uint256 _maxAmountAirdropToken)
        public
        onlyRole(BACKEND_ADMIN)
        whenNotPaused
    {
        maxAmountAirdropToken = _maxAmountAirdropToken;
    }

    /**
     * @notice Indicates wheter a particular address is waiting for a token delivered through airdrop
     * @param _account: address to be checked wheter is waiting for the airdrop to be delivered
     * @return boolean inidicating whether an address is waiting for an airdrop token
     */
    function amIEnrolledInAirdrop(address _account) public view returns (bool) {
        return isAccountInAirdrop[_account];
    }

    /**
     * @notice Used for a user to enroll in the airdrop process
     * @param _account: address to be added to the list of future receivers of the airdrop
     */
    function enrollInAirDrop(address _account) public whenNotPaused {
        require(
            !hasAccountReceivedAirdrop[_account],
            "Airdrop: airdrop already claimed."
        );
        require(
            !isAccountInAirdrop[_account],
            "Airdrop: You are already enrolled in the airdrop."
        );
        require(
            airdropAccountList.length <= maxAmountAirdropToken,
            "Airdrop: list is full."
        );

        isAccountInAirdrop[_account] = true;
        airdropAccountList.push(_account);
        emit EnrolledInAirdrop(_account);
    }

    /**
     * @notice Sends airdrop tokens in batches.
     * @param _addresses: list of accounts to received airdrop tokens
     */
    function sendAirdropBatch(address[] memory _addresses)
        public
        onlyRole(BACKEND_ADMIN)
        whenNotPaused
    {
        for (uint256 ix = 0; ix < _addresses.length; ix++) {
            address _account = _addresses[ix];
            if (isAccountInAirdrop[_account]) {
                pachaCuyToken.safeTransfer(_account, 1);
                isAccountInAirdrop[_account] = false;
                hasAccountReceivedAirdrop[_account] = true;
                emit AirdropDelivered(_account);
            }
        }
    }

    /**
     * @notice Delivers airdrop tokens to all enrolled accounts
     * @dev It does verify whether accounto has received a token previously
     */
    function sendAllRemainingAirdrop()
        public
        onlyRole(BACKEND_ADMIN)
        whenNotPaused
    {
        for (uint256 ix = 0; ix < airdropAccountList.length; ix++) {
            address _account = airdropAccountList[ix];
            if (isAccountInAirdrop[_account]) {
                pachaCuyToken.safeTransfer(_account, 1);
                isAccountInAirdrop[_account] = false;
                hasAccountReceivedAirdrop[_account] = true;
                emit AirdropDelivered(_account);
            }
        }
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

// airdrop puede hacer burn?
// que pasa con los que no reclaman su airdrop?
// hay monto para realizar el airdrop o es de un solo token?
