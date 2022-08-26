// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVesting {
    function createVestingSchema(
        address _account,
        uint256 _fundsToVest,
        uint256 _vestingPeriods,
        uint256 _releaseDay,
        string memory _roleOfAccount
    ) external;
}
