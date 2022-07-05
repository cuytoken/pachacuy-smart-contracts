// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRandomNumberGenerator {
    function requestRandomNumber(address _account) external;

    function requestRandomNumber(address _account, uint32 _amountNumbers)
        external;

    function requestRandomNumberBouncing(
        address _account,
        uint32 _amountNumbers
    ) external view returns (uint256[] memory);
}
