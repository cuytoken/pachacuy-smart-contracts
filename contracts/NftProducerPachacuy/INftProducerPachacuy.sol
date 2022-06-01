// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INftProducerPachacuy {
    function mintGuineaPigNft(
        address account,
        uint256 gender, // 0, 1
        uint256 race, // 1 -> 4
        uint256 idForJsonFile, // 1 -> 8
        uint256 price
    ) external returns (uint256);

    function mintLandNft(
        address account,
        uint256 idForJsonFile,
        uint256 price,
        bytes memory data
    ) external returns (uint256);

    function mintPachaPassNft(
        address _account,
        uint256 _landUuid,
        uint256 _uuidPachaPass,
        uint256 _typeOfDistribution,
        uint256 _price,
        string memory _transferMode
    ) external;

    function getLandData(uint256 _uuid)
        external
        returns (
            bool isLand,
            bool isPublic,
            uint256 uuid,
            uint256 pachaPassUuid,
            uint256 pachaPassPrice,
            uint256 typeOfDistribution,
            uint256 location,
            uint256 idForJsonFile,
            uint256 wasPurchased,
            address owner
        );

    function mintChakra(
        address _account,
        uint256 _pachaUuid,
        uint256 _chakraPrice
    ) external returns (uint256);

    function purchaseFood(
        uint256 _chakraUuid,
        uint256 _amountFood,
        uint256 _guineaPigUuid
    ) external returns (uint256 availableFood);

    function mintMisayWasi(
        address _account,
        uint256 _pachaUuid,
        uint256 _misayWasiPrice
    ) external;

    function createTicketIdRaffle() external returns (uint256 _raffleUuid);

    function purchaseTicketRaffle(
        address _account,
        uint256 _ticketUuid,
        uint256 _misayWasiUuid,
        uint256 _amountOfTickets
    ) external;

    function mintQhatuWasi(
        uint256 _pachaUuid,
        address _account,
        uint256 _qhatuWasiPrice
    ) external;
}
