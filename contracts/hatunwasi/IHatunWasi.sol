// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IHatunWasi {
    struct HatunWasiInfo {
        bool hasHatunWasi;
    }

    function hasHatunWasi(address _account) external view returns (bool);

    function burnHatunWasi(address _account, uint256 _pachaUuid) external;
}
