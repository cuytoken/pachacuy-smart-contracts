// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGuineaPig {
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

    function feedGuineaPig(uint256 _guineaPigUuid, uint256 _amountFood)
        external;

    function tokenUri(string memory _prefix, uint256 _guineaPigUuid)
        external
        view
        returns (string memory);

    function requestRandomNumber(address _account, uint256 _amount)
        external
        returns (uint256[] memory randomNumbers);
}
