// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWiracocha {
    struct WiracochaInfo {
        bool hasWiracocha;
    }

    function hasWiracocha(address _account, uint256 _pachaUuid)
        external
        view
        returns (bool);
}
