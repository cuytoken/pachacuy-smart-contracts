// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGuineaPig {
    function registerGuineaPig(
        address _account,
        uint256 _gender,
        uint256 _race,
        uint256 _idForJsonFile,
        uint256 _guineaPigUuid
    ) external;

    function getRaceGenderGuineaPig(
        uint256 _ix,
        uint256 _raceRN, // [1, 100]
        uint256 _genderRN // [0, 1]
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            string memory
        );

    function feedGuineaPig(uint256 _guineaPigUuid) external;
}
