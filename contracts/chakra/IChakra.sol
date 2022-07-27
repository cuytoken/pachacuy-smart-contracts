// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IChakra {
    struct ChakraInfo {
        address owner;
        uint256 chakraUuid;
        uint256 pachaUuid;
        uint256 creationDate;
        uint256 priceOfChakra;
        uint256 pricePerFood;
        uint256 totalFood;
        uint256 availableFood;
        bool hasChakra;
    }

    function getChakraWithUuid(uint256 _chakraUuid)
        external
        returns (ChakraInfo memory);

    function consumeFoodFromChakra(uint256 _chakraUuid, uint256 _amountFood)
        external
        returns (uint256);

    function burnChakra(uint256 _chakraUuid) external;
}
