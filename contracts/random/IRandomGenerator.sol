// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRandomGenerator {
    /**
     * @notice Emitted when the key has been modified
     */
    event KeyHashSet(bytes32 keyHash);

    /**
     * @notice Emitted when the fee has been modified
     */
    event FeeSet(uint256 fee);

    /**
     * @notice Emitted when the address of the VRF Coordinator contract has been modified
     */
    event VrfCoordinatorSet(address indexed vrfCoordinator);

    /**
     * @notice Emitted when a new random request has been sent for the VRF Coordinator
     */
    event VRFRequested(bytes32 indexed requestId);

    /**
     * @notice Emitted when a new request for a random number has been submitted
     * @param _acccount The indexed ID for which random number request has been made
     * @param requestId The indexed ID of the request used to get the results of the RNG service
     */
    event RandomNumberRequested(
        address indexed _acccount,
        bytes32 indexed requestId
    );

    /**
     * @notice Emitted when an existing request for a random number has been completed
     * @param _account The indexed ID for which random number request has been made
     * @param requestId The indexed ID of the request used to get the results of the Rand Number Generator service
     * @param randomNumber The random number produced by the 3rd-party service
     */
    event RandomNumberCompleted(
        address indexed _account,
        bytes32 indexed requestId,
        uint256 randomNumber
    );

    /**
     * @notice Emitted when the Random Number Generator contract is close to run out of Link Tokens
     * @param linkBalance The remaining amount of Link Tokens
     */
    event BalanceAlmostZero(uint256 linkBalance);

    /**
     * @notice Gets the Fee for making a Request against 3d-party service (Chainlink VRF)
     * @return feeToken The address of the token that is used to pay fees
     * @return requestFee The fee required to be paid to make a request
     */
    function getRequestFee()
        external
        view
        returns (address feeToken, uint256 requestFee);

    /**
     * @notice Sends a request for a random number to the 3rd-party service
     * @dev Some services will complete the request immediately, others may have a time-delay
     * @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
     * @param _account The ID for which random number request has been made
     * @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.
     * The calling contract should "lock" all activity until the result is available via the `requestId`
     */
    function requestRandomNumber(address _account)
        external
        returns (uint32 lockBlock);

    /**
     * @notice Checks if the request for randomness from the 3rd-party service has completed
     * @dev For time-delayed requests, this function is used to check/confirm completion
     * @param _account The ID for which random number request has been made
     * @return isCompleted True if the request has completed and a random number is available, false otherwise
     */
    function isRequestComplete(address _account)
        external
        view
        returns (bool isCompleted);

    /**
     * @dev Returns the block number at which the RNG service will start generating time-delayed randomness
     * @param _account The ID for which the 'lockBlock' is returned
     * @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.
     * The calling contract should "lock" all activity until the result is available via the `requestId`
     */
    function getLockBlock(address _account)
        external
        view
        returns (uint256 lockBlock);

    /**
     * @notice Gets the random number produced by the 3rd-party service
     * @param _account The ID for which random number request has been made
     * @return randomNumber The random number
     */
    function getRandomNumber(address _account)
        external
        view
        returns (uint256 randomNumber);
}
