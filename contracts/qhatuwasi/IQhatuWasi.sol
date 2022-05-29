// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IQhatuWasi {
    function registerQhatuWasi(
        uint256 _qhatuWasiUuid,
        address _owner,
        uint256 _qhatuWasiPrice
    ) external;
}
