// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IHatunWasi {
    struct HatunWasiInfo {
        bool hasHatunWasi;
    }

    function getAHatunWasi(address _account, uint256 _pachaUuid)
        external
        returns (HatunWasiInfo memory);

    function registerHatunWasi(
        address _account,
        uint256 _pachaUuid,
        uint256 _hatunWasiUuid
    ) external;

    function burnHatunWasi(address _account, uint256 _pachaUuid) external;
}
