// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPacha {
    function registerPacha(
        address _account,
        uint256 _idForJsonFile,
        uint256 _pachaUuid
    ) external;

    function isPachaAlreadyTaken(uint256 _location) external returns (bool);
}
