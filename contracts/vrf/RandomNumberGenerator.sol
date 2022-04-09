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
////                                            Random Number Generator                                          ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../vrf/CallbackInterface.sol";

/// @custom:security-contact lee@cuytoken.com
contract RandomNumberGenerator is
    VRFConsumerBaseV2,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /**
     * @dev Interface for VRF Coordinator
     */
    VRFCoordinatorV2Interface vrfCoordinator;

    /**
     * @dev The request fee of the Chainlink VRF
     */
    uint96 internal fee;

    /**
     * @dev Minimum LINK tokens balance in subscription before triggering an event
     */
    uint96 minimunLinkBalance;

    /**
     * @dev Interface for Link Token
     */
    LinkTokenInterface linkToken;

    /**
     * @dev Subscription Id from VRF Coordinator
     */
    uint64 subscriptionId;

    /**
     * @dev VRF Coordinator Address for current chain
     */
    address vrfCoordinatorAddress;

    /**
     * @dev The keyhash used by the Chainlink VRF
     */
    bytes32 internal keyHash;

    /**
     * @dev LINK Token address
     */
    address link;

    /**
     * @dev Amount of confirmatinons for the VRF Random Number to be valid
     */
    uint16 requestConfirmations;

    /**
     * @dev A mapping from address to a boolean representing if a request is ongoing for that address
     */
    mapping(address => bool) internal isRequestOngoing;

    /**
     * @param walletAddress Address for which the random number is generated
     * @param smartCAddress Smart Contract that is requesting the random number
     */
    struct Caller {
        address walletAddress;
        address smartCAddress;
    }
    /**
     * @dev A mapping from Chainlink request id to address for which the request has been made
     */
    mapping(uint256 => Caller) internal chainlinkRequestForAccount;

    /**
     * @dev A mapping from the account to the latest random number obtained for this account
     */
    mapping(uint256 => uint256) public randomNumber;

    /**
     * @dev A mapping from the account to the latest random number obtained for this account
     */
    mapping(address => bool) internal whiteListSmartContract;

    /**
     * @notice Emitted when the key has been modified
     */
    event KeyHashSet(bytes32 keyHash);

    /**
     * @notice Emitted when the fee has been modified
     */
    event FeeSet(uint256 fee);

    /**
     * @dev Indicates whether LINK tones are low in the VRF subscription
     * @param minimunLinkBalance The minimum balance of LINK tokens before givin the alert
     * @param balance The current balance of LINK tokens for the vrf subscription
     */
    event LinkBalanceIsLow(uint96 minimunLinkBalance, uint96 balance);

    event Sucess(bool _success);

    /**
     * @dev Indicated the data after the Random Number has been generated by VRF
     * @param requestId The request id of the Chainlink VRF
     * @param smartCAddress Smart Contract who is calling the random number function
     * @param walletAddress Wallet address for which the random number is generated
     * @param randomWords Array of random words generated by the VRF
     */
    event RandomNumberDelivered(
        uint256 requestId,
        address smartCAddress,
        address walletAddress,
        uint256[] randomWords
    );

    event ErrorFromVrfCallback(
        string error,
        uint256 requestId,
        address smartCAddress,
        address walletAddress
    );

    event ErrorNotHandled(
        bytes reason,
        uint256 requestId,
        address smartCAddress,
        address walletAddress
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;
        vrfCoordinatorAddress = 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;
        link = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
        requestConfirmations = 3;
        subscriptionId = 420;
        fee = 2 * 10**17;
        minimunLinkBalance = 5 * 10**18;

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __VRF_init(vrfCoordinatorAddress);

        // Granting roles
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());

        // VRF Coordinator set up
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        linkToken = LinkTokenInterface(link);
    }

    /**
     * @dev Consumed by the Client to request a random number
     */
    function requestRandomNumber(address _account) external {
        _requestRandomNumber(_account, 1);
    }

    /**
     * @dev Consumed by the Client to request a random number
     */
    function requestRandomNumber(address _account, uint32 _amountNumbers)
        external
    {
        _requestRandomNumber(_account, _amountNumbers);
    }

    function _requestRandomNumber(address _account, uint32 _amountNumbers)
        internal
    {
        // verify that this function is called by an accepted address
        require(
            whiteListSmartContract[_msgSender()],
            "RNG: Request from unauthorized address"
        );

        // check if the subscription has enough link to make the request
        (uint96 balance, , , ) = vrfCoordinator.getSubscription(subscriptionId);
        require(balance >= fee, "RNG: Not enough LINK to pay the request fee!");

        if (balance < minimunLinkBalance) {
            emit LinkBalanceIsLow(minimunLinkBalance, balance);
        }

        require(
            !isRequestOngoing[_account],
            "RNG: A request for this address is already ongoing!"
        );

        // mark the request as ongoing
        isRequestOngoing[_account] = true;

        // Calculate amount of gas to be spent
        uint32 _callbackGasLimit = 1000000;

        // execute the request to VRF coordinator
        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            _callbackGasLimit,
            _amountNumbers
        );

        // store the request id for the account and smart contract caller
        // *** Emit an event before receiving the random number
        chainlinkRequestForAccount[requestId] = Caller(_account, _msgSender());
    }

    /**
     * @notice Checks if the request for randomness from the 3rd-party service has completed
     * @dev For time-delayed requests, this function is used to check/confirm completion
     * @param _account The address for which random number request has been made
     * @return True if the request has completed and a random number is available, false otherwise
     */
    function isRequestComplete(address _account) external view returns (bool) {
        return !isRequestOngoing[_account];
    }

    // Callback function for the VRF request
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // Wallet address and SC for which the request was made
        address _account = chainlinkRequestForAccount[requestId].walletAddress;
        address _smartc = chainlinkRequestForAccount[requestId].smartCAddress;

        // mark the request as completed
        isRequestOngoing[_account] = false;

        // store the first random number and the rest goes to the event
        randomNumber[requestId] = randomWords[0];

        emit RandomNumberDelivered(requestId, _smartc, _account, randomWords);

        try
            CallbackInterface(_smartc).fulfillRandomness(_account, randomWords)
        {} catch Error(string memory reason) {
            emit ErrorFromVrfCallback(reason, requestId, _smartc, _account);
        } catch (bytes memory reason) {
            emit ErrorNotHandled(reason, requestId, _smartc, _account);
        }
    }

    function addToWhiteList(address _smartContractAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whiteListSmartContract[_smartContractAddress] = true;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function resetOngoinTransaction(address _account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isRequestOngoing[_account] = false;
    }

    /**
     * @notice Allows owner to set the Chainlink VRF keyhash
     * @param _keyhash The keyhash to be used by the Chainlink VRF
     */
    function setKeyHash(bytes32 _keyhash)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        keyHash = _keyhash;
        emit KeyHashSet(keyHash);
    }

    /**
     * @notice Allows owner to set the fee per request required by the Chainlink VRF
     * @param _fee The fee to be charged for a request
     */
    function setFee(uint96 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fee = _fee;
        emit FeeSet(fee);
    }

    /**
     * @notice Allows owner to set the subscriptionId required by the Chainlink VRF
     * @param _subscriptionId The new subscription Id of a different VRF Subscription
     */
    function setSubscriptionId(uint64 _subscriptionId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        subscriptionId = _subscriptionId;
    }

    /**
     * @notice Allows owner to set the minimum amount of LINK required in the smart contract
     * @param _minimunLinkBalance The new minimum amount to be compared against the balance
     */
    function setMinimunLinkBalance(uint96 _minimunLinkBalance)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minimunLinkBalance = _minimunLinkBalance;
    }

    function withdraw(uint256 amount, address to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        linkToken.transfer(to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
