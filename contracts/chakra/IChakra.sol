// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IChakra {
    function registerChakra(
        address _account,
        uint256 _pachaUuid,
        uint256 _chackraUuid,
        uint256 _chakraPrice,
        uint256 _prizePerFood
    ) external;

    function getFoodPriceNOwner(uint256 _chakraUuid)
        external
        view
        returns (uint256 foodPrice, address owner);

    function consumeFoodFromChakra(uint256 _chakraUuid)
        external
        returns (uint256);

    function burnChakra(uint256 _chakraUuid) external;
}
