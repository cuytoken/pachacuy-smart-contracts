// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPacha {
    struct PachaInfo {
        bool isPacha;
        bool isPublic;
        uint256 uuid;
        uint256 pachaPassUuid;
        uint256 pachaPassPrice;
        uint256 typeOfDistribution;
        uint256 idForJsonFile;
        uint256 wasPurchased;
        uint256 location;
        address owner;
        uint256 price;
    }

    function registerPacha(
        address _account,
        uint256 _idForJsonFile,
        uint256 _pachaUuid,
        uint256 _price
    ) external;

    function isPachaAlreadyTaken(uint256 _location) external returns (bool);

    function tokenUri(string memory _prefix, uint256 _pachaUuid)
        external
        view
        returns (string memory);

    function getPachaWithUuid(uint256 _pachaUuid)
        external
        view
        returns (PachaInfo memory);

    function registerPachaPass(
        address _account,
        uint256 _pachaUuid,
        uint256 _pachaPassUuid,
        string memory _transferMode
    ) external;
}
