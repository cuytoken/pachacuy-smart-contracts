// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWiracocha {
    struct WiracochaInfo {
        bool hasWiracocha;
    }

    function getWiracochaInfoForAccount(address _account, uint256 _pachaUuid)
        external
        returns (WiracochaInfo memory);

    function registerWiracocha(
        address _account,
        uint256 _pachaUuid,
        uint256 _wiracochaUuid,
        bytes memory data
    ) external;
}
