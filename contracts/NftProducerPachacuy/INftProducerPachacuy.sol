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

    function createPachaPassId() external returns (uint256 _pachaPassUuid);

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

    function mintPachaPass(
        address _account,
        uint256 _pachaUuid,
        uint256 _pachaPassUuid
    ) external;
}
