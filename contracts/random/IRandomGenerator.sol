// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRandomGenerator {
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external;

    function getRandomNumber() external returns (bytes32 requestId);
}
