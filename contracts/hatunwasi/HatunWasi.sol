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
////                                                   HatunWasi                                                 ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/// @custom:security-contact lee@cuytoken.com
contract HatunWasi is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    /**
     * @dev Details the information of a Hatun Wasi. Additional properties attached for its campaign
     * @param owner: Wallet address of the current owner of the Hatun Wasi
     * @param hatunWasiUuid: Uuid of the Hatun Wasi when it was minted
     * @param pachaUuid: Uuid of the pacha where the Hatun Wasi belongs to
     * @param creationDate: Date when the Hatun Wasi was minted
     * @param hasHatunWasi: Indicates wheter a Hatun Wasi exists exists or not
     */
    struct HatunWasiInfo {
        address owner;
        uint256 hatunWasiUuid;
        uint256 pachaUuid;
        uint256 creationDate;
        bool hasHatunWasi;
    }
    // Owner Hatun Wasi -> Pacha UUID -> Struct of HatunWasi Info
    mapping(address => mapping(uint256 => HatunWasiInfo)) uuidToHatunWasiInfo;

    // List of Available Hatun Wasis
    HatunWasiInfo[] listOfHatunWasis;
    // Hatun Wasi uuid => array index
    mapping(uint256 => uint256) internal _hatunWasiIx;

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
     * @param _account: Wallet address of the current owner of the Pacha
     * @param _pachaUuid: Uuid of the pacha when it was minted
     * @param _hatunWasiUuid: Uuid of the Hatun Wasi when it was minted
     */
    function registerHatunWasi(
        address _account,
        uint256 _pachaUuid,
        uint256 _hatunWasiUuid
    ) external onlyRole(GAME_MANAGER) {
        require(
            !uuidToHatunWasiInfo[_account][_pachaUuid].hasHatunWasi,
            "Hatun Wasi: It has one Hatun Wasi already"
        );

        HatunWasiInfo memory hatunWasi = HatunWasiInfo({
            owner: _account,
            hatunWasiUuid: _hatunWasiUuid,
            pachaUuid: _pachaUuid,
            creationDate: block.timestamp,
            hasHatunWasi: true
        });
        uuidToHatunWasiInfo[_account][_pachaUuid] = hatunWasi;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _hatunWasiIx[_hatunWasiUuid] = current;
        listOfHatunWasis.push(hatunWasi);
    }

    function burnHatunWasi(address _account, uint256 _pachaUuid)
        external
        onlyRole(GAME_MANAGER)
    {
        uint256 _hatunWasiUuid = uuidToHatunWasiInfo[_account][_pachaUuid]
            .hatunWasiUuid;
        delete uuidToHatunWasiInfo[_account][_pachaUuid];
        _removeHatunWasiWithUuid(_hatunWasiUuid);
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function _removeHatunWasiWithUuid(uint256 _hatuWasiUuid) internal {
        uint256 _length = listOfHatunWasis.length;
        if (_length == 1) {
            listOfHatunWasis.pop();
            delete _hatunWasiIx[_hatuWasiUuid];
            _tokenIdCounter.decrement();
        }

        // get _ix of element to remove
        uint256 _ix = _hatunWasiIx[_hatuWasiUuid];
        delete _hatunWasiIx[_hatuWasiUuid];

        // temp of El at last position of array to be removed
        HatunWasiInfo memory _hatunWasi = listOfHatunWasis[_length - 1];

        // point last El to index to be replaced
        _hatunWasiIx[_hatunWasi.hatunWasiUuid] = _ix;

        // swap last El from last position to index to be replaced
        listOfHatunWasis[_ix] = _hatunWasi;

        // remove last element
        listOfHatunWasis.pop();

        // decrease counter since array decreased in one
        _tokenIdCounter.decrement();
    }

    function tokenUri(uint256 _hatuWasiUuid)
        public
        view
        returns (string memory)
    {}

    function getListOfHatunWasis()
        external
        view
        returns (HatunWasiInfo[] memory)
    {
        return listOfHatunWasis;
    }

    function getAHatunWasi(address _account, uint256 _pachaUuid)
        external
        view
        returns (HatunWasiInfo memory)
    {
        return uuidToHatunWasiInfo[_account][_pachaUuid];
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
