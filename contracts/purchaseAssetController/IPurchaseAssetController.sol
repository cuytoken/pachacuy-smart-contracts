// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPurchaseAssetController {
    function transferPcuyFromUserToPoolReward(
        address _account,
        uint256 _pcuyAmount
    ) external;

    function transferPcuyFromPoolRewardToUser(
        address _account,
        uint256 _pcuyAmount
    ) external;
}
