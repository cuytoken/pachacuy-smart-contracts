// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRandomGenerator.sol";

interface IContractReceivingRNG {
    function fulfillRandomness(address account, uint256 randomness) external;
}

contract RandomGenerator is IRandomGenerator, VRFConsumerBase, AccessControl {
    /**
     * @dev The keyhash used by the Chainlink VRF
     */
    bytes32 internal keyHash;

    /**
     * @dev The request fee of the Chainlink VRF
     */
    uint256 internal fee;

    /**
     * @dev Interface for Link Token
     */
    IERC20 linkToken;

    /**
     * @dev The offset limit of the withdraw to check near zero
     */
    uint256 public withdrawOffset;

    /**
     * @dev A list of blocks to be locked at based on past requests mapped by address
     */
    mapping(address => uint32) internal requestLockBlock;

    /**
     * @dev A mapping from Chainlink request id to address for which the request has been made
     */
    mapping(bytes32 => address) internal chainlinkRequestForAccount;

    /**
     * @dev A mapping from the account to the latest random number obtained for this account
     */
    mapping(address => uint256) internal randomNumbers;

    /**
     * @dev A mapping from address to a boolean representing if a request is ongoing for that address
     */
    mapping(address => bool) internal requestOngoing;

    uint256 public randomResult;

    /**
     * @dev Generic contract receiving random number
     */
    IContractReceivingRNG public contractReceivingRandom;

    bytes32 public constant BACKEND_ADMIN_ROLE =
        keccak256("BACKEND_ADMIN_ROLE");

    constructor(address _vrfCoordinator, address _link)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        linkToken = IERC20(_link);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        withdrawOffset = 10000000000000000;
        emit VrfCoordinatorSet(_vrfCoordinator);
        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        fee = 1 * 10**17;
    }

    /**
     * @notice Returns the address of LINK Token used by Random Number Generator
     */
    function getLink() external view returns (address) {
        return address(LINK);
    }

    /**
     * @notice Allows owner to set the Chainlink VRF keyhash
     * @param _keyhash The keyhash to be used by the Chainlink VRF
     */
    function setKeyHash(bytes32 _keyhash) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "RNG: You don't have the permission to call this function!"
        );
        keyHash = _keyhash;
        emit KeyHashSet(keyHash);
    }

    /**
     * @notice Allows owner to set the fee per request required by the Chainlink VRF
     * @param _fee The fee to be charged for a request
     */
    function setFee(uint256 _fee) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "RNG: You don't have the permission to call this function!"
        );
        fee = _fee;
        emit FeeSet(fee);
    }

    /**
     * @notice Allows owner and backend to set offset to check near zero
     * @param _offset The offset to be checked for withdraw LINK
     */
    function setWithdrawOffset(uint256 _offset) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "You don't have the permission to call this function!"
        );
        withdrawOffset = _offset;
    }

    /**
     * @notice Gets the Fee for making a Request against an RNG service
     * @return feeToken The address of the token that is used to pay fees
     * @return requestFee The fee required to be paid to make a request
     */
    function getRequestFee()
        external
        view
        override
        returns (address feeToken, uint256 requestFee)
    {
        return (address(LINK), fee);
    }

    /**
     * @notice Sends a request for a random number to the 3rd-party service
     * @dev Some services will complete the request immediately, others may have a time-delay
     * @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
     * @param _account The ID for which random number request has been made
     * @return lockBlock The block number at which the RNG service will start generating time-delayed
     * randomness. The calling contract
     * should "lock" all activity until the result is available via the `requestId`
     */
    function requestRandomNumber(address _account)
        external
        override
        returns (uint32 lockBlock)
    {
        require(
            address(contractReceivingRandom) == _msgSender(),
            "RNG: This function can be called only by the Contract Receiving Random!"
        );
        // check if the contract has enough link to make the request
        require(
            linkToken.balanceOf(address(this)) >= fee,
            "RNG: Not enough link to process the transaction!"
        );
        // check if a request is already ongoing
        require(
            !requestOngoing[_account],
            "RNG: A request for wthi this ID is already ongoing!"
        );

        lockBlock = uint32(block.number);
        requestLockBlock[_account] = lockBlock;

        // mark the request
        requestOngoing[_account] = true;

        // send request (costs fee)
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit VRFRequested(requestId);

        chainlinkRequestForAccount[requestId] = _account;

        emit RandomNumberRequested(_account, requestId);
    }

    /**
     * @notice Checks if the request for randomness from the 3rd-party service has completed
     * @dev For time-delayed requests, this function is used to check/confirm completion
     * @param _account The ID for which random number request has been made
     * @return isCompleted True if the request has completed and a random number is available, false otherwise
     */
    function isRequestComplete(address _account)
        external
        view
        override
        returns (bool isCompleted)
    {
        return !requestOngoing[_account];
    }

    /**
     * @dev Returns the block number at which the RNG service will start generating time-delayed randomness
     * @param _account The ID for which the 'lockBlock' is returned
     * @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.
     * The calling contract should "lock" all activity until the result is available via the `requestId`
     */
    function getLockBlock(address _account)
        external
        view
        override
        returns (uint256 lockBlock)
    {
        return requestLockBlock[_account];
    }

    /**
     * @notice Gets the random number produced by the 3rd-party service
     * @param _account The ID for which random number request has been made
     * @return randomNumber The random number
     */
    function getRandomNumber(address _account)
        external
        view
        override
        returns (uint256 randomNumber)
    {
        return randomNumbers[_account];
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        address _account = chainlinkRequestForAccount[requestId];

        // Store random value
        randomNumbers[_account] = randomness;

        requestOngoing[_account] = false;

        emit RandomNumberCompleted(_account, requestId, randomness);

        contractReceivingRandom.fulfillRandomness(
            chainlinkRequestForAccount[requestId],
            randomness
        );
    }

    /**
     * @notice Used by Admin to withdraw LINK tokens
     * @param _account address which will receive the LINK tokens withdrawn from the RandomNumberGenerator
     * @param _amount_link amount of LINK tokens that are going to be withdrawn
     */
    function withdrawLink(address _account, uint256 _amount_link) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "You don't have the permission to call this function!"
        );

        LINK.transfer(_account, _amount_link);
        if (LINK.balanceOf(address(this)) < withdrawOffset)
            emit BalanceAlmostZero(LINK.balanceOf(address(this)));
    }

    function setContractToReceiveRandomNG(
        address contractReceivingRandomAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractReceivingRandom = IContractReceivingRNG(
            contractReceivingRandomAddress
        );
    }
}
