// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INftProducerPachacuy {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}
