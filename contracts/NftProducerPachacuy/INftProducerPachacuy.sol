// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INftProducerPachacuy {
    function mintGuineaPigNft(
        address account,
        uint256 race, // 1 -> 4
        uint256 idForJsonFile, // 1 -> 8
        bytes memory data
    ) external returns (uint256);

    function mintLandNft(
        address account,
        uint256 idForJsonFile,
        bytes memory data
    ) external returns (uint256);
}
