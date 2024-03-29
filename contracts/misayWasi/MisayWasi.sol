/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////      ___         ___           ___           ___           ___           ___           ___                  ////
////     /  /\       /  /\         /  /\         /__/\         /  /\         /  /\         /__/\          ___    ////
////    /  /::\     /  /::\       /  /:/         \  \:\       /  /::\       /  /:/         \  \:\        /__/|   ////
////   /  /:/\:\   /  /:/\:\     /  /:/           \__\:\     /  /:/\:\     /  /:/           \  \:\      |  |:|   ////
////  /  /:/~/:/  /  /:/~/::\   /  /:/  ___   ___ /  /::\   /  /:/~/::\   /  /:/  ___   ___  \  \:\     |  |:|   ////
//// /__/:/ /:/  /__/:/ /:/\:\ /__/:/  /  /\ /__/\  /:/\:\ /__/:/ /:/\:\ /__/:/  /  /\ /__/\  \__\:\  __|__|:|   ////
//// \  \:\/:/   \  \:\/:/__\/ \  \:\ /  /:/ \  \:\/:/__\/ \  \:\/:/__\/ \  \:\ /  /:/ \  \:\ /  /:/ /__/::::\   ////
////  \  \::/     \  \::/       \  \:\  /:/   \  \::/       \  \::/       \  \:\  /:/   \  \:\  /:/     ~\~~\:\  ////
////   \  \:\      \  \:\        \  \:\/:/     \  \:\        \  \:\        \  \:\/:/     \  \:\/:/        \  \:\ ////
////    \  \:\      \  \:\        \  \::/       \  \:\        \  \:\        \  \::/       \  \::/          \__\/ ////
////     \__\/       \__\/         \__\/         \__\/         \__\/         \__\/         \__\/                 ////
////                                                                                                             ////
////                                                 LAND OF CUYS                                                ////
////                                                  Misay Wasi                                                   ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../info/IPachacuyInfo.sol";
import "../NftProducerPachacuy/INftProducerPachacuy.sol";
import "../purchaseAssetController/IPurchaseAssetController.sol";
import "../vrf/IRandomNumberGenerator.sol";
import "../binarysearch/IBinarySearch.sol";
import "../token/IPachaCuy.sol";

/// @custom:security-contact lee@cuytoken.com
contract MisayWasi is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");
    bytes32 public constant RNG_GENERATOR = keccak256("RNG_GENERATOR");

    IPachacuyInfo pachacuyInfo;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    /**
     * @dev Details the information of a Tatacuy. Additional properties attached for its campaign
     * @param owner: Wallet address of the current owner of the Tatacuy
     * @param misayWasiUuid: Uuid of the misay waysi when it was minted
     * @param pachaUuid: Uuid of the pacha where the misay waysi belongs to
     * @param creationDate: Date when the misay waysi was minted
     * @param ticketPrice: Price ticket to participate in the raffle
     * @param ticketUuid: Uuid of the ticket of the Misay Wasi
     * @param misayWasiPrice: Price in PCUY of the Misay Wasi
     * @param rafflePrize: Prize of winning at the raffle
     * @param numberTicketsPurchased: Number of raffle tickets bought
     * @param campaignStartDate: Timestamp when the raffle initiated
     * @param campaignEndDate: Timestamp when the raffle ends
     * @param isCampaignActive: Indicates wheter this misay waysi is running a raffle or not
     * @param hasMisayWasi: Indicates wheter a misay wasi exists or not
     */
    struct MisayWasiInfo {
        address owner;
        uint256 misayWasiUuid;
        uint256 pachaUuid;
        uint256 creationDate;
        uint256 ticketPrice;
        uint256 ticketUuid;
        uint256 misayWasiPrice;
        uint256 rafflePrize;
        uint256 numberTicketsPurchased;
        uint256 campaignStartDate;
        uint256 campaignEndDate;
        bool isCampaignActive;
        bool hasMisayWasi;
        address[] listOfParticipants;
    }
    // MisayWasi UUID  -> Struct of MisayWasi Info
    mapping(uint256 => MisayWasiInfo) internal uuidToMisayWasiInfo;

    // List of Available MisayWasis
    uint256[] listUuidActiveRaffles;
    // MisayWasi uuid => array index
    mapping(uint256 => uint256) internal _misayWasiIx;

    // ticket uuid => misay wasi uuid
    mapping(uint256 => uint256) _ticketUuidToMisayWasiUuid;

    // misay wasi uuid => wallet address => amount of tickets
    mapping(uint256 => mapping(address => uint256)) _misayWasiToTickets;

    // list misay wasis to raffle at once
    uint256[] misayWasiUuids;

    /**
     * @param winner: Wallet address of the winner of this raffle contest
     * @param misayWasiUuid: Uuid of the Misay Wasi where the raffle contest took place
     * @param rafflePrize: Net prize (minus fee) of the Misay Wasi allocated by the Misay Wasi's owner
     * @param raffleTax: Tax applied to the prize
     * @param ticketUuid: Uuid of the ticket purchased at this Misay Wasi
     */
    event RaffleContestFinished(
        address winner,
        uint256 misayWasiUuid,
        uint256 rafflePrize,
        uint256 raffleTax,
        uint256 ticketUuid
    );

    event RaffleStarted(
        uint256 misayWasiUuid,
        uint256 rafflePrize,
        uint256 ticketPrice,
        uint256 campaignStartDate,
        uint256 campaignEndDate,
        uint256 pachaUuid
    );

    event PurchaseTicketFromMisayWasi(
        address account,
        uint256 misayWasiUuid,
        uint256 pachaUuid,
        uint256 ticketPrice,
        uint256 amountOfTickets
    );

    event PurchaseMisayWasi(
        address account,
        uint256 misayWasiUuid,
        uint256 pachaUuid,
        uint256 creationDate,
        uint256 misayWasiPrice,
        uint256 balanceConsumer
    );

    struct HistoricWinners {
        address owner;
        uint256 ticketUuid;
        uint256 misayWasiUuid;
        uint256 pachaUuid;
        address winner;
        uint256 netPrize;
        uint256 feePrize;
    }

    // misayWasi uuid => HistoricWinners
    mapping(uint256 => HistoricWinners[]) historicWinners;

    IERC20 public usdcToken;
    address public _bizWalletAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(GAME_MANAGER, _msgSender());
    }

    function validateMint(bytes memory _data) external view returns (bool) {
        (address _account, uint256 _pachaUuid, ) = abi.decode(
            _data,
            (address, uint256, uint256)
        );
        uint256 _q = INftProducerPachacuy(pachacuyInfo.nftProducerAddress())
            .balanceOf(_account, _pachaUuid);

        return _q > 0;
    }

    // /**
    //  * @dev Trigger when it is minted
    //  * @param _account: Wallet address of the current owner of the Pacha
    //  * @param _pachaUuid: Uuid of the pacha when it was minted
    //  * @param _misayWasiUuid: Uuid of the Tatacuy when it was minted
    //  * @param _misayWasiPrice: Price in PCUY of the Misay Wasi
    //  */
    function registerNft(bytes memory _data) external {
        (
            address _account,
            uint256 _pachaUuid,
            uint256 _misayWasiPrice,
            uint256 _misayWasiUuid
        ) = abi.decode(_data, (address, uint256, uint256, uint256));

        MisayWasiInfo memory misayWasiInfo = MisayWasiInfo({
            owner: _account,
            misayWasiUuid: _misayWasiUuid,
            pachaUuid: _pachaUuid,
            creationDate: block.timestamp,
            ticketPrice: 0,
            ticketUuid: 0,
            misayWasiPrice: _misayWasiPrice,
            rafflePrize: 0,
            numberTicketsPurchased: 0,
            campaignStartDate: 0,
            campaignEndDate: 0,
            isCampaignActive: false,
            hasMisayWasi: true,
            listOfParticipants: new address[](0)
        });
        uuidToMisayWasiInfo[_misayWasiUuid] = misayWasiInfo;

        uint256 balanceConsumer = IPachaCuy(pachacuyInfo.pachaCuyTokenAddress())
            .balanceOf(_account);

        emit PurchaseMisayWasi(
            _account,
            _misayWasiUuid,
            _pachaUuid,
            block.timestamp,
            _misayWasiPrice,
            balanceConsumer
        );
    }

    /**
     * @notice initiated by the owner of the misay wasi who deposits funds
     * @param _misayWasiUuid: Uuid of the Misay Wasi where the owner is creating a raffle
     * @param _rafflePrize: Prize of the raffle to be given by the owner
     * @param _ticketPrice: Price to pay by a participant of the raffle
     * @param _campaignEndDate: Timestamp ending date where the raffle will finish
     */
    function startMisayWasiRaffle(
        uint256 _misayWasiUuid,
        uint256 _rafflePrize,
        uint256 _ticketPrice,
        uint256 _campaignEndDate
    ) external {
        require(_ticketPrice > 0, "Misay Wasi: Zero price");

        _transferFromUSDC(_msgSender(), _bizWalletAddress, _rafflePrize);

        MisayWasiInfo storage misayWasiInfo = uuidToMisayWasiInfo[
            _misayWasiUuid
        ];

        require(
            !misayWasiInfo.isCampaignActive,
            "Misay Wasi: Campaign is active"
        );

        require(
            misayWasiInfo.owner == _msgSender(),
            "Misay Wasi: Not the owner"
        );

        uint256 _ticketUuid = INftProducerPachacuy(
            pachacuyInfo.nftProducerAddress()
        ).createTicketIdRaffle();

        misayWasiInfo.rafflePrize = _rafflePrize;
        misayWasiInfo.ticketPrice = _ticketPrice;
        misayWasiInfo.campaignEndDate = _campaignEndDate;
        misayWasiInfo.isCampaignActive = true;
        misayWasiInfo.ticketUuid = _ticketUuid;
        misayWasiInfo.campaignStartDate = block.timestamp;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _misayWasiIx[_misayWasiUuid] = current;
        listUuidActiveRaffles.push(_misayWasiUuid);

        // link ticket uuid to misay wasi uuid
        _ticketUuidToMisayWasiUuid[_ticketUuid] = _misayWasiUuid;

        emit RaffleStarted(
            _misayWasiUuid,
            _rafflePrize,
            _ticketPrice,
            block.timestamp,
            _campaignEndDate,
            misayWasiInfo.pachaUuid
        );
    }

    function registerTicketPurchase(
        address _account,
        uint256 _misayWasiUuid,
        uint256 _amountOfTickets,
        bool newCustomer
    ) external onlyRole(GAME_MANAGER) {
        _misayWasiToTickets[_misayWasiUuid][_account] += _amountOfTickets;

        MisayWasiInfo storage misayWasiInfo = uuidToMisayWasiInfo[
            _misayWasiUuid
        ];

        misayWasiInfo.numberTicketsPurchased += _amountOfTickets;
        if (newCustomer) {
            misayWasiInfo.listOfParticipants.push(_account);
        }

        emit PurchaseTicketFromMisayWasi(
            _account,
            _misayWasiUuid,
            misayWasiInfo.pachaUuid,
            misayWasiInfo.ticketPrice,
            _amountOfTickets
        );
    }

    /**
     * @notice Initiated by the backend
     * @param _misayWasiUuids Array of Uuid of the Misay Wasis that will start the raffle
     * @dev Called only by the cloud using an access role
     * @dev Called every day at 10 AM UTC-5
     */
    function startRaffleContest(uint256[] memory _misayWasiUuids)
        external
        onlyRole(GAME_MANAGER)
    {
        misayWasiUuids = _misayWasiUuids;

        uint256 _randomNumber = uint256(
            keccak256(abi.encodePacked(_msgSender(), block.timestamp))
        );

        _fulfillRandomness(_randomNumber);
    }

    // Callback from VRF
    function _fulfillRandomness(uint256 _randomNumber) internal {
        uint256[] memory _misayWasiUuids = misayWasiUuids;
        misayWasiUuids = new uint256[](0);
        uint256 length = _misayWasiUuids.length;
        for (uint256 ix = 0; ix < length; ix++) {
            _findWinnerOfRaffle(_misayWasiUuids[ix], _randomNumber);
        }
    }

    function _findWinnerOfRaffle(uint256 _misayWasiUuid, uint256 _randomNumber)
        internal
    {
        MisayWasiInfo memory misayWasiInfo = uuidToMisayWasiInfo[
            _misayWasiUuid
        ];
        address[] memory _participants = misayWasiInfo.listOfParticipants;
        uint256 _lengthP = _participants.length;
        if (_lengthP == 0) {
            // Gives full prize to owner
            _transferFromUSDC(
                _bizWalletAddress,
                misayWasiInfo.owner,
                misayWasiInfo.rafflePrize
            );

            // remove misay wasi from active list
            _removeMisayWasiFromActive(_misayWasiUuid);
            return;
        }
        _randomNumber =
            (_randomNumber % misayWasiInfo.numberTicketsPurchased) +
            1;
        uint256[] memory _accumulative = new uint256[](_lengthP);
        uint256 temp = 0;
        for (uint256 ix = 0; ix < _lengthP; ix++) {
            temp += _misayWasiToTickets[_misayWasiUuid][_participants[ix]];
            _accumulative[ix] = temp;
        }
        uint256 _winnerIx = IBinarySearch(pachacuyInfo.binarySearchAddress())
            .binarySearch(_accumulative, _randomNumber);

        uint256 _feePrize = (misayWasiInfo.rafflePrize *
            pachacuyInfo.raffleTax()) / 100;
        uint256 _netPrize = misayWasiInfo.rafflePrize - _feePrize;

        address _winner = _participants[_winnerIx];
        emit RaffleContestFinished(
            _winner,
            _misayWasiUuid,
            _netPrize,
            _feePrize,
            misayWasiInfo.ticketUuid
        );

        historicWinners[_misayWasiUuid].push(
            HistoricWinners({
                owner: misayWasiInfo.owner,
                ticketUuid: misayWasiInfo.ticketUuid,
                misayWasiUuid: misayWasiInfo.misayWasiUuid,
                pachaUuid: misayWasiInfo.pachaUuid,
                winner: _winner,
                netPrize: _netPrize,
                feePrize: _feePrize
            })
        );

        // Gives prize
        _transferFromUSDC(_bizWalletAddress, _winner, _netPrize);

        // Cleans raffle from Misay Wasi
        _removeMisayWasiFromActive(_misayWasiUuid);
    }

    function transfer(
        address _oldOwner,
        address _newOwner,
        uint256 _uuid,
        uint256 _amount
    ) external onlyRole(GAME_MANAGER) {
        if (uuidToMisayWasiInfo[_uuid].hasMisayWasi) {
            MisayWasiInfo storage misayWasiInfo = uuidToMisayWasiInfo[_uuid];
            misayWasiInfo.owner = _newOwner;
            misayWasiInfo.pachaUuid = 0;
            return;
        } else {
            MisayWasiInfo storage mswsInfo = uuidToMisayWasiInfo[
                _ticketUuidToMisayWasiUuid[_uuid]
            ];
            require(mswsInfo.hasMisayWasi, "MSWS: Wrong ticket uuid");

            // tranferring a ticket from an old campaign
            if (mswsInfo.ticketUuid != _uuid) return;

            // increase and decrease amount of tickets for a wallet
            uint256 oldOwnerQ = _misayWasiToTickets[mswsInfo.misayWasiUuid][
                _oldOwner
            ];
            require(oldOwnerQ >= _amount, "MSWS: Not enough tickets");
            _misayWasiToTickets[mswsInfo.misayWasiUuid][_oldOwner] -= _amount;
            // remove from list of participants
            if (_misayWasiToTickets[mswsInfo.misayWasiUuid][_oldOwner] == 0) {
                address[] storage _participants = mswsInfo.listOfParticipants;
                uint256 _lengthP = _participants.length;
                for (uint256 ix = 0; ix < _lengthP; ix++) {
                    if (_participants[ix] == _oldOwner) {
                        _participants[ix] = _participants[_lengthP - 1];
                        _participants.pop();
                        break;
                    }
                }
            }

            bool newCustomer = INftProducerPachacuy(
                pachacuyInfo.nftProducerAddress()
            ).balanceOf(_newOwner, _uuid) == 0;
            // include in list of participants
            if (newCustomer) {
                mswsInfo.listOfParticipants.push(_newOwner);
            }
            _misayWasiToTickets[mswsInfo.misayWasiUuid][_newOwner] += _amount;
        }
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function setUsdcTokenAddress(address _usdcAddress)
        public
        onlyRole(GAME_MANAGER)
    {
        usdcToken = IERC20(_usdcAddress);
    }

    function _transferFromUSDC(
        address from,
        address to,
        uint256 amount
    ) internal {
        // allowance
        uint256 usdcAllowance = usdcToken.allowance(from, address(this));
        require(usdcAllowance >= amount, "MSWS: Not enough USDC allowance");

        // balance
        uint256 usdcBalance = usdcToken.balanceOf(from);
        require(usdcBalance >= amount, "MSWS: Not enough USDC balance");

        /// Transfer funds
        bool success = usdcToken.transferFrom(from, to, amount);
        require(success, "MSWS: USDC Transfer Failed");
    }

    function getHistoricWinners(uint256 _misayWasiUuid)
        external
        view
        returns (HistoricWinners[] memory)
    {
        return historicWinners[_misayWasiUuid];
    }

    function _removeMisayWasiFromActive(uint256 _misayWasiUuid) internal {
        MisayWasiInfo storage misayWasiInfo = uuidToMisayWasiInfo[
            _misayWasiUuid
        ];
        misayWasiInfo.isCampaignActive = false;
        misayWasiInfo.listOfParticipants = new address[](0);
        misayWasiInfo.campaignEndDate = block.timestamp;
        misayWasiInfo.ticketPrice = 0;
        misayWasiInfo.ticketUuid = 0;
        misayWasiInfo.rafflePrize = 0;
        misayWasiInfo.numberTicketsPurchased = 0;

        // remove uuid from list
        uint256 _ix = _misayWasiIx[_misayWasiUuid];
        delete _misayWasiIx[_misayWasiUuid];

        if (listUuidActiveRaffles.length == 1) {
            listUuidActiveRaffles.pop();
            _tokenIdCounter.decrement();
            return;
        }
        uint256 _lastUuid = listUuidActiveRaffles[
            listUuidActiveRaffles.length - 1
        ];
        listUuidActiveRaffles[_ix] = _lastUuid;
        listUuidActiveRaffles.pop();
        _tokenIdCounter.decrement();
        _misayWasiIx[_lastUuid] = _ix;
    }

    /**
     * @notice Get a list of Misay Wasis that are ready to start their raffle contest
     * @dev It verifies that campaign ending data is less than actual timestamp
     */
    function getListOfMisayWasisReadyToRaffle()
        external
        view
        returns (uint256[] memory _listOfRafflesToStart)
    {
        _listOfRafflesToStart = new uint256[](0);

        for (uint256 ix = 0; ix < listUuidActiveRaffles.length; ix++) {
            uint256 activeRaffleUuid = listUuidActiveRaffles[ix];
            if (
                uuidToMisayWasiInfo[activeRaffleUuid].campaignEndDate <
                block.timestamp
            ) {
                _listOfRafflesToStart[
                    _listOfRafflesToStart.length
                ] = activeRaffleUuid;
            }
        }
    }

    function getListOfActiveMWRaffles()
        external
        view
        returns (MisayWasiInfo[] memory listOfMisayWasis)
    {
        listOfMisayWasis = new MisayWasiInfo[](listUuidActiveRaffles.length);
        for (uint256 ix = 0; ix < listUuidActiveRaffles.length; ix++) {
            listOfMisayWasis[ix] = uuidToMisayWasiInfo[
                listUuidActiveRaffles[ix]
            ];
        }
    }

    function getMiswayWasiWithTicketUuid(uint256 _ticketUuid)
        external
        view
        returns (MisayWasiInfo memory)
    {
        return uuidToMisayWasiInfo[_ticketUuidToMisayWasiUuid[_ticketUuid]];
    }

    function setPachacuyInfoAddress(address _infoAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachacuyInfo = IPachacuyInfo(_infoAddress);
    }

    function getMisayWasiWithUuid(uint256 _misayWasiUuid)
        external
        view
        returns (MisayWasiInfo memory)
    {
        return uuidToMisayWasiInfo[_misayWasiUuid];
    }

    function setBizWalletAddress(address bizWalletAddress)
        public
        onlyRole(GAME_MANAGER)
    {
        _bizWalletAddress = bizWalletAddress;
    }

    // _uuid: either _misayWasiUuid or _pachaPassUuid
    function tokenUri(string memory _prefix, uint256 _uuid)
        external
        view
        returns (string memory)
    {
        if (uuidToMisayWasiInfo[_uuid].hasMisayWasi) {
            return string(abi.encodePacked(_prefix, "MISAYWASI.json"));
        } else if (
            uuidToMisayWasiInfo[_ticketUuidToMisayWasiUuid[_uuid]].hasMisayWasi
        ) {
            return string(abi.encodePacked(_prefix, "TICKETMISAYWASI.json"));
        }
        return "";
    }

    ///////////////////////////////////////////////////////////////
    ////                   STANDARD FUNCTIONS                  ////
    ///////////////////////////////////////////////////////////////

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
