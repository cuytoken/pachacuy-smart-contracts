// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWiracocha {
    struct WiracochaInfo {
        bool hasWiracocha;
    }

    function hasWiracocha(address _account) external view returns (bool);

    function registerWiracocha(
        address _account,
        uint256 _pachaUuid,
        uint256 _wiracochaUuid,
        bytes memory data
    ) external;
}
