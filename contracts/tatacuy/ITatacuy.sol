// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITatacuy {
    struct TatacuyInfo {
        bool hasTatacuy;
    }

    function registerTatacuy(
        address _account,
        uint256 _pachaUuid,
        uint256 _uuid,
        bytes memory data
    ) external;
}
