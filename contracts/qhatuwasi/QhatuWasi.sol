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
////                                                   QhatuWasi                                                 ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../purchaseAssetController/IPurchaseAssetController.sol";
import "../info/IPachacuyInfo.sol";
import "../token/IPachaCuy.sol";
import "../NftProducerPachacuy/INftProducerPachacuy.sol";
import "hardhat/console.sol";

/// @custom:security-contact lee@cuytoken.com
contract QhatuWasi is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    IPachacuyInfo pachacuyInfo;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    struct QhatuWasiInfo {
        uint256 uuid;
        uint256 pachaUuid;
        address owner;
        uint256 creationDate;
        uint256 totalPcuyDeposited;
        uint256 pcuyForCurrentCampaign;
        uint256 samiPointsToGiveAway;
        uint256 qhatuWasiPrice;
        uint256 prizePerView;
    }
    // uuid => Qhatu Wasi
    mapping(uint256 => QhatuWasiInfo) internal _uuidToQhatuWasiInfo;

    // List of Qhatu Wasis
    uint256[] listUuidQhatuWasis;
    // Qhatu Wasi uuid => array index
    mapping(uint256 => uint256) internal _qhatuWasiIx;

    event QhatuWasiCampaignStarted(
        uint256 campaignTax,
        uint256 netPcuyDeposited,
        uint256 samiPointsToGiveAway,
        uint256 qhatuWasiuuid,
        address owner,
        uint256 _prizePerView
    );

    event PurchaseQhatuWasi(
        address owner,
        uint256 qhatuWasiUuid,
        uint256 pachaUuid,
        uint256 qhatuWasiPrice,
        uint256 creationDate,
        uint256 balanceConsumer
    );

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

    /**
     * @dev Trigger when it is minted
     * @param _qhatuWasiUuid: uuid of the qhatu wasi when it was minted
     * @param _owner: wallet owner of th owner
     */
    function registerQhatuWasi(
        uint256 _qhatuWasiUuid,
        uint256 _pachaUuid,
        address _owner,
        uint256 _qhatuWasiPrice
    ) external onlyRole(GAME_MANAGER) {
        QhatuWasiInfo memory _qhatuWasiInfo = QhatuWasiInfo({
            uuid: _qhatuWasiUuid,
            pachaUuid: _pachaUuid,
            owner: _owner,
            creationDate: block.timestamp,
            totalPcuyDeposited: 0,
            pcuyForCurrentCampaign: 0,
            samiPointsToGiveAway: 0,
            qhatuWasiPrice: _qhatuWasiPrice,
            prizePerView: 0
        });
        _uuidToQhatuWasiInfo[_qhatuWasiUuid] = _qhatuWasiInfo;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _qhatuWasiIx[_qhatuWasiUuid] = current;
        listUuidQhatuWasis.push(_qhatuWasiUuid);

        uint256 balanceConsumer = IPachaCuy(pachacuyInfo.pachaCuyTokenAddress())
            .balanceOf(_owner);

        emit PurchaseQhatuWasi(
            _owner,
            _qhatuWasiUuid,
            _pachaUuid,
            _qhatuWasiPrice,
            block.timestamp,
            balanceConsumer
        );
    }

    /**
     *
     * @param _qhatuWasiUuid: Uuid of the Qhatu Wasi when it was minted
     * @param _amountPcuyCampaign: Amount in PCUY to be deposited by the campaign
     * @param _prizePerView: Amount in PCUY to be paid when someone sees the add until the end
     */
    function startQhatuWasiCampaign(
        uint256 _qhatuWasiUuid,
        uint256 _amountPcuyCampaign,
        uint256 _prizePerView
    ) external {
        QhatuWasiInfo storage _qhatuWasiInfo = _uuidToQhatuWasiInfo[
            _qhatuWasiUuid
        ];
        require(
            _msgSender() == _qhatuWasiInfo.owner,
            "Qhatu W.: Not the owner"
        );

        IPurchaseAssetController(pachacuyInfo.purchaseACAddress())
            .transferPcuyFromUserToPoolReward(
                _msgSender(),
                _amountPcuyCampaign
            );

        uint256 _tax = (_amountPcuyCampaign * pachacuyInfo.qhatuWasiTax()) /
            100;
        uint256 _net = _amountPcuyCampaign - _tax;

        uint256 _samiPointsToGiveAway = pachacuyInfo.convertPcuyToSami(_net);

        _qhatuWasiInfo.totalPcuyDeposited += _net;
        _qhatuWasiInfo.pcuyForCurrentCampaign = _net;
        _qhatuWasiInfo.samiPointsToGiveAway = _samiPointsToGiveAway;
        uint256 _prizePerViewSami = pachacuyInfo.convertPcuyToSami(
            _prizePerView
        );
        _qhatuWasiInfo.prizePerView = _prizePerViewSami;

        emit QhatuWasiCampaignStarted(
            _tax,
            _net,
            _samiPointsToGiveAway,
            _qhatuWasiUuid,
            _qhatuWasiInfo.owner,
            _prizePerViewSami
        );
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

    function registerNft(bytes memory _data) external {
        (
            address _owner,
            uint256 _pachaUuid,
            uint256 _qhatuWasiPrice,
            uint256 _qhatuWasiUuid
        ) = abi.decode(_data, (address, uint256, uint256, uint256));

        QhatuWasiInfo memory _qhatuWasiInfo = QhatuWasiInfo({
            uuid: _qhatuWasiUuid,
            pachaUuid: _pachaUuid,
            owner: _owner,
            creationDate: block.timestamp,
            totalPcuyDeposited: 0,
            pcuyForCurrentCampaign: 0,
            samiPointsToGiveAway: 0,
            qhatuWasiPrice: _qhatuWasiPrice,
            prizePerView: 0
        });
        _uuidToQhatuWasiInfo[_qhatuWasiUuid] = _qhatuWasiInfo;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _qhatuWasiIx[_qhatuWasiUuid] = current;
        listUuidQhatuWasis.push(_qhatuWasiUuid);

        uint256 balanceConsumer = IPachaCuy(pachacuyInfo.pachaCuyTokenAddress())
            .balanceOf(_owner);

        emit PurchaseQhatuWasi(
            _owner,
            _qhatuWasiUuid,
            _pachaUuid,
            _qhatuWasiPrice,
            block.timestamp,
            balanceConsumer
        );
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function tokenUri(uint256 _chakraUuid)
        public
        view
        returns (string memory)
    {}

    function getListOfQhatuWasi()
        external
        view
        returns (QhatuWasiInfo[] memory listOfQhatuWasis)
    {
        listOfQhatuWasis = new QhatuWasiInfo[](listUuidQhatuWasis.length);
        for (uint256 ix = 0; ix < listUuidQhatuWasis.length; ix++) {
            listOfQhatuWasis[ix] = _uuidToQhatuWasiInfo[listUuidQhatuWasis[ix]];
        }
    }

    function getQhatuWasiWithUuid(uint256 _qhatuWasiUuid)
        external
        view
        returns (QhatuWasiInfo memory)
    {
        return _uuidToQhatuWasiInfo[_qhatuWasiUuid];
    }

    function setPachacuyInfoAddress(address _pachacuyInfo)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachacuyInfo = IPachacuyInfo(_pachacuyInfo);
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
