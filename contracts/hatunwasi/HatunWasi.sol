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
    // Hatun Wasi UUID -> Struct of HatunWasi Info
    mapping(uint256 => HatunWasiInfo) uuidToHatunWasiInfo;

    // List of Available Hatun Wasis
    uint256[] listUuidOfHatunWasi;
    // Hatun Wasi uuid => array index
    mapping(uint256 => uint256) internal _hatunWasiIx;

    mapping(address => bool) public ownerHasHatunWasi;

    event MintHatunWasi(
        address owner,
        uint256 hatunWasiUuid,
        uint256 pachaUuid,
        uint256 creationDate
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
     * @param _account: Wallet address of the current owner of the Pacha
     * @param _pachaUuid: Uuid of the pacha when it was minted
     * @param _hatunWasiUuid: Uuid of the Hatun Wasi when it was minted
     */
    function registerHatunWasi(
        address _account,
        uint256 _pachaUuid,
        uint256 _hatunWasiUuid
    ) external onlyRole(GAME_MANAGER) {
        require(!ownerHasHatunWasi[_account], "Hatun Wasi: Has a HatunWasi");

        // ownerHasHatunWasi[_account] = true;

        HatunWasiInfo memory hatunWasi = HatunWasiInfo({
            owner: _account,
            hatunWasiUuid: _hatunWasiUuid,
            pachaUuid: _pachaUuid,
            creationDate: block.timestamp,
            hasHatunWasi: true
        });
        uuidToHatunWasiInfo[_hatunWasiUuid] = hatunWasi;

        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _hatunWasiIx[_hatunWasiUuid] = current;
        listUuidOfHatunWasi.push(_hatunWasiUuid);

        emit MintHatunWasi(
            _account,
            _hatunWasiUuid,
            _pachaUuid,
            block.timestamp
        );
    }

    function burnHatunWasi(uint256 _hatunWasiUuid)
        external
        onlyRole(GAME_MANAGER)
    {
        ownerHasHatunWasi[uuidToHatunWasiInfo[_hatunWasiUuid].owner] = false;
        delete uuidToHatunWasiInfo[_hatunWasiUuid];
        _removeHatunWasiWithUuid(_hatunWasiUuid);
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPER FUNCTIONS                    ////
    ///////////////////////////////////////////////////////////////

    function _removeHatunWasiWithUuid(uint256 _hatuWasiUuid) internal {
        uint256 _length = listUuidOfHatunWasi.length;
        if (_length == 1) {
            listUuidOfHatunWasi.pop();
            delete _hatunWasiIx[_hatuWasiUuid];
            _tokenIdCounter.decrement();
        }

        // get _ix of element to remove
        uint256 _ix = _hatunWasiIx[_hatuWasiUuid];
        delete _hatunWasiIx[_hatuWasiUuid];

        // temp of El at last position of array to be removed
        uint256 _hatunWasi = listUuidOfHatunWasi[_length - 1];

        // point last El to index to be replaced
        _hatunWasiIx[_hatuWasiUuid] = _ix;

        // swap last El from last position to index to be replaced
        listUuidOfHatunWasi[_ix] = _hatunWasi;

        // remove last element
        listUuidOfHatunWasi.pop();

        // decrease counter since array decreased in one
        _tokenIdCounter.decrement();
    }

    function tokenUri(uint256 _hatunWasiUuid)
        public
        view
        returns (string memory)
    {}

    function getListOfHatunWasis()
        external
        view
        returns (HatunWasiInfo[] memory listOfHatunWasis)
    {
        listOfHatunWasis = new HatunWasiInfo[](listUuidOfHatunWasi.length);
        for (uint256 ix = 0; ix < listUuidOfHatunWasi.length; ix++) {
            listOfHatunWasis[ix] = uuidToHatunWasiInfo[listUuidOfHatunWasi[ix]];
        }
    }

    function getHatunWasiWithUuid(uint256 _hatunWasiUuid)
        external
        view
        returns (HatunWasiInfo memory)
    {
        return uuidToHatunWasiInfo[_hatunWasiUuid];
    }

    function hasHatunWasi(address _account) external view returns (bool) {
        return ownerHasHatunWasi[_account];
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
