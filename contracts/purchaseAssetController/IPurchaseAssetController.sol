// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPurchaseAssetController {
    function transferPcuyFromUserToPoolReward(
        address _account,
        uint256 _pcuyAmount
    ) external;

    function transferPcuyWithTax(
        address _from,
        address _to,
        uint256 _pcuyAmount
    ) external returns (uint256 _net, uint256 _fee);

    function transferPcuyFromPoolRewardToUser(
        address _account,
        uint256 _pcuyAmount
    ) external;
}
