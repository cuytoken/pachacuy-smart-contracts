// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMisayWasi {
    struct MisayWasiInfo {
        address owner;
        uint256 misayWasiUuid;
        uint256 pachaUuid;
        uint256 creationDate;
        uint256 ticketPrice;
        uint256 ticketUuid;
        uint256 misayWasiPrice;
        uint256 rafflePrize;
        uint256 numberOfParticipants;
        uint256 campaignStartDate;
        uint256 campaignEndDate;
        bool isCampaignActive;
        bool hasMisayWasi;
    }

    function registerMisayWasi(
        address _account,
        uint256 _pachaUuid,
        uint256 _misayWasiUuid,
        uint256 _misayWasiPrice
    ) external;

    function getMisayWasiWithUuid(uint256 _misayWasiUuid)
        external
        returns (MisayWasiInfo memory);

    function registerTicketPurchase(
        address _account,
        uint256 _misayWasiUuid,
        uint256 _amountOfTickets,
        bool newCustomer
    ) external;
}
