// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface CallbackInterface {
    function fulfillRandomness(address, uint256[] memory) external;
}
