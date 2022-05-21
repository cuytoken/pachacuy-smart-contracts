// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPachaCuy {
    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);
}
