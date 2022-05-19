// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPachacuyInfo {
    function totalFood() external returns (uint256);

    function chakraAddress() external returns (address);

    function wiracochaAddress() external returns (address);

    function tatacuyAddress() external returns (address);

    function poolRewardAddress() external returns (address);

    function hatunWasiAddress() external returns (address);

    function purchaseTax() external returns (uint256);
}
