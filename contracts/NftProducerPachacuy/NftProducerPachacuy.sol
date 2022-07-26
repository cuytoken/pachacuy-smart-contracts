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
////                                            NFT PRODUCER PACHACUY                                            ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

// Interfaces
import "../tatacuy/ITatacuy.sol";
import "../wiracocha/IWiracocha.sol";
import "../chakra/IChakra.sol";
import "../hatunwasi/IHatunWasi.sol";
import "../info/IPachacuyInfo.sol";
import "../misayWasi/IMisayWasi.sol";
import "../guineapig/IGuineaPig.sol";
import "../pacha/IPacha.sol";
import "../qhatuwasi/IQhatuWasi.sol";
import "hardhat/console.sol";

/// @custom:security-contact lee@cuytoken.com
contract NftProducerPachacuy is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    ERC1155SupplyUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    IPachacuyInfo pachacuyInfo;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    // NFT types
    // bytes32 public constant TATACUY = keccak256("TATACUY");
    // bytes32 public constant WIRACOCHA = keccak256("WIRACOCHA");
    // bytes32 public constant CHAKRA = keccak256("CHAKRA");
    // bytes32 public constant HATUNWASI = keccak256("HATUNWASI");
    // bytes32 public constant MISAYWASI = keccak256("MISAYWASI");
    // bytes32 public constant QHATUWASI = keccak256("QHATUWASI");
    // bytes32 public constant GUINEAPIG = keccak256("GUINEAPIG");
    // bytes32 public constant PACHA = keccak256("PACHA");
    bytes32 public constant TICKETRAFFLE = keccak256("TICKETRAFFLE");
    bytes32 public constant PACHAPASS = keccak256("PACHAPASS");
    bytes32 public constant BURNED = keccak256("BURNED");

    // Struct Nft Info
    struct NftInfo {
        bytes32 nftType;
        bool canTransfer;
        address scAddress;
        bool requiredRole;
        string errorMessage;
        string errorRegister;
    }
    mapping(bytes32 => NftInfo) public _nftInfo;

    event Uuid(uint256 uuid);
    event UuidAndAmount(uint256 uuid, uint256 amount);

    // Map owner -> uuid[]
    mapping(address => uint256[]) internal _ownerToUuids;

    // Token name
    string internal _name;
    // Token symbol
    string internal _symbol;
    // Token prefix
    string internal _prefix;

    // Map uuid with NFT type
    mapping(uint256 => bytes32) internal _nftTypes;

    // Pachacuy Smart Contracts allowed to burn
    mapping(address => bool) public allowedToBurn;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory name_, string memory symbol_)
        public
        initializer
    {
        _prefix = "ipfs://QmbbGgo93M6yr5WSUMj53SWN2vC7L6aMS1GZSPNkVRY8e4/";

        __ERC1155_init(_prefix);
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        _name = name_;
        _symbol = symbol_;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(URI_SETTER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(GAME_MANAGER, _msgSender());

        // starts counter at one
        _tokenIdCounter.increment();
    }

    // DONE
    // function mintGuineaPigNft(
    // function mintLandNft(
    // function mintWiracocha(uint256 _pachaUuid) external returns (uint256) {
    // function mintTatacuy(uint256 _pachaUuid) external returns (uint256) {
    // function mintChakra(
    // function mintHatunWasi(uint256 _pachaUuid) external returns (uint256) {
    // function mintMisayWasi(
    // function mintQhatuWasi(

    function purchaseFood(
        address _account,
        uint256 _chakraUuid,
        uint256 _amountFood,
        uint256 _guineaPigUuid
    ) external onlyRole(GAME_MANAGER) returns (uint256 availableFood) {
        require(
            balanceOf(_account, _guineaPigUuid) > 0,
            "NFP: No guinea pig found"
        );

        // update Guinea Pig life span
        IGuineaPig(pachacuyInfo.guineaPigAddress()).feedGuineaPig(
            _guineaPigUuid,
            _amountFood
        );

        availableFood = IChakra(pachacuyInfo.chakraAddress())
            .consumeFoodFromChakra(_chakraUuid, _amountFood);
    }

    function createTicketIdRaffle()
        external
        onlyRole(GAME_MANAGER)
        returns (uint256 _raffleUuid)
    {
        uint256 uuid = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // save type of uuid minted
        _nftTypes[uuid] = TICKETRAFFLE;

        return uuid;
    }

    function createPachaPassId()
        external
        onlyRole(GAME_MANAGER)
        returns (uint256 _pachaPassUuid)
    {
        uint256 uuid = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // save type of uuid minted
        _nftTypes[uuid] = PACHAPASS;

        return uuid;
    }

    /**
     * @notice Used when someone is purchasing a pacha pass
     * @notice Only callable by Purchase Asset Controller
     */
    function mintPachaPass(
        address _account,
        uint256 _pachaUuid,
        uint256 _pachaPassUuid
    ) external onlyRole(GAME_MANAGER) {
        require(balanceOf(_account, _pachaPassUuid) == 0, "NFP: has one");

        _mint(_account, _pachaPassUuid, 1, "");

        // save in list of uuids for owner
        _ownerToUuids[_account].push(_pachaPassUuid);

        IPacha(pachacuyInfo.pachaAddress()).registerPachaPass(
            _account,
            _pachaUuid,
            _pachaPassUuid,
            "purchased"
        );

        emit Uuid(_pachaPassUuid);
    }

    /**
     * @notice Mints a Pacha Pass when the Pacha has chose typeDistribution = 1 (no public sale)
     * @param _accounts: list of wallet address that will receive a pacha pass
     * @param _pachaUuid: uuid of the Pacha from where the Pacha Passes will be minted
     */
    function mintPachaPassAsOwner(
        address[] memory _accounts,
        uint256 _pachaUuid
    ) external {
        IPacha.PachaInfo memory pacha = IPacha(pachacuyInfo.pachaAddress())
            .getPachaWithUuid(_pachaUuid);

        require(pacha.owner == _msgSender(), "NFP: Not the owner");
        require(pacha.isPacha, "NFP: Not a pacha");
        require(!pacha.isPublic, "NFP: Land must be private");
        require(pacha.pachaPassUuid > 0, "NFP: PachaPass do not exist");

        uint256 _pachaPassUuid = pacha.pachaPassUuid;
        address pachaSCAddress = pachacuyInfo.pachaAddress();
        for (uint256 i = 0; i < _accounts.length; i++) {
            _mint(_accounts[i], _pachaPassUuid, 1, "");

            IPacha(pachaSCAddress).registerPachaPass(
                _accounts[i],
                _pachaUuid,
                _pachaPassUuid,
                "transferred"
            );
        }

        emit Uuid(_pachaPassUuid);
    }

    function purchaseTicketRaffle(
        address _account,
        uint256 _ticketUuid,
        uint256 _misayWasiUuid,
        uint256 _amountOfTickets
    ) external onlyRole(GAME_MANAGER) {
        // has tickets already?
        bool newCustomer = balanceOf(_account, _ticketUuid) == 0;

        // mint the tickets of the raffle
        _mint(_account, _ticketUuid, _amountOfTickets, "");

        // save in list of uuids for owner
        _ownerToUuids[_account].push(_ticketUuid);

        IMisayWasi(pachacuyInfo.misayWasiAddress()).registerTicketPurchase(
            _account,
            _misayWasiUuid,
            _amountOfTickets,
            newCustomer
        );
        emit UuidAndAmount(_ticketUuid, balanceOf(_account, _ticketUuid));
    }

    function mint(
        bytes32 _nftType,
        bytes calldata _data,
        address _account
    ) external returns (uint256 uuid) {
        NftInfo memory nft = _nftInfo[_nftType];
        require(nft.scAddress != address(0), "Nft P.: Wrong NFT type");

        // validate role
        if (nft.requiredRole) {
            require(hasRole(MINTER_ROLE, _msgSender()), "Nft P.: No privilege");
        } else {
            address _accountData = abi.decode(_data[:42], (address));
            require(_account == _msgSender(), "Nft P.: Address mismatch 1");
            require(_accountData == _msgSender(), "Nft P.: Address mismatch 2");
        }

        // validate mint
        (bool success, bytes memory data) = nft.scAddress.call(
            abi.encodeWithSignature("validateMint(bytes)", _data)
        );
        // require(success, "Nft P.: Wrong call");
        require(success, nft.errorMessage);
        require(abi.decode(data, (bool)), "Nft P.: Invalid mint");
        // get counter
        uuid = _tokenIdCounter.current();

        // concat uuid to _data
        bytes memory _dataWithUuid = bytes.concat(_data, abi.encode(uuid));

        // mint
        _mint(_account, uuid, 1, "");

        // _ownerToUuids
        _ownerToUuids[_account].push(uuid);

        // _nftTypes
        _nftTypes[uuid] = _nftType;

        // register
        (bool success2, ) = nft.scAddress.call(
            abi.encodeWithSignature("registerNft(bytes)", _dataWithUuid)
        );
        // require(success2, "Nft P.: Error registering NFT");
        require(success2, nft.errorRegister);

        // increase counter
        _tokenIdCounter.increment();

        // emit Uuuid
        emit Uuid(uuid);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 uuid,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(_nftInfo[_nftTypes[uuid]].canTransfer, "NFP: Cannot transfer");

        // remove uuid from _ownerToUuids => uuid[]
        _rmvElFromOwnerToUuids(from, uuid);

        // add that uuid to new owner's array
        _ownerToUuids[to].push(uuid);

        _safeTransferFrom(from, to, uuid, amount, data);

        // update smart contract
        (bool success, ) = _nftInfo[_nftTypes[uuid]].scAddress.call(
            abi.encodeWithSignature(
                "transfer(address,address,uint256,uint256)",
                from,
                to,
                uuid,
                amount
            )
        );
        require(success, "NFP: Failed transfer");
    }

    function burn(
        address account,
        uint256 uuid,
        uint256 value
    ) public virtual override {
        require(
            allowedToBurn[_msgSender()] || _msgSender() == account,
            "ERC1155: caller is not owner nor approved"
        );
        _nftTypes[uuid] = BURNED;
        _burn(account, uuid, value);
    }

    function _rmvElFromOwnerToUuids(address _account, uint256 _uuid) internal {
        require(_ownerToUuids[_account].length > 0, "NFP: Array is empty");

        if (_ownerToUuids[_account].length == 1) {
            if (_ownerToUuids[_account][0] == _uuid) {
                _ownerToUuids[_account].pop();
                return;
            } else {
                revert("NFP: Not found");
            }
        }

        // find the index of _uuid
        uint256 i;
        for (i = 0; i < _ownerToUuids[_account].length; i++) {
            if (_ownerToUuids[_account][i] == _uuid) break;
        }
        require(i != _ownerToUuids[_account].length, "NFP: Not found");

        // remove the element
        _ownerToUuids[_account][i] = _ownerToUuids[_account][
            _ownerToUuids[_account].length - 1
        ];
        _ownerToUuids[_account].pop();
    }

    ///////////////////////////////////////////////////////////////
    ////                   HELPERS FUNCTIONS                   ////
    ///////////////////////////////////////////////////////////////
    function setBurnOp(address[] memory _scAddressArr)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 ix = 0; ix < _scAddressArr.length; ix++) {
            allowedToBurn[_scAddressArr[ix]] = true;
        }
    }

    /**
     * @notice Indicates whether a Guinea Pig is allows to enter a Pacha
     * @param _account Wallet to be validated against the Pacha
     * @param _pachaUuid Uuid of the pacha to check the access of _account
     */
    function isGuineaPigAllowedInPacha(address _account, uint256 _pachaUuid)
        external
        view
        returns (bool)
    {
        IPacha.PachaInfo memory pacha = IPacha(pachacuyInfo.pachaAddress())
            .getPachaWithUuid(_pachaUuid);

        // pacha onwer
        if (pacha.owner == _account) return true;
        // pacha do not exist
        if (!pacha.isPacha) return false;
        // pacha is public
        if (pacha.isPublic) return true;

        // All private land must have a uuid for its pachapass
        require(pacha.pachaPassUuid > 0, "NFP: Uuid's pachapass missing");
        if (balanceOf(_account, pacha.pachaPassUuid) > 0) {
            return true;
        } else return false;
    }

    function fillNftsInfo(bytes[] memory _dataArray) external {
        for (uint256 i = 0; i < _dataArray.length; i++) {
            (
                bytes32 _nftType,
                bool _canTransfer,
                address _scAddress,
                bool _requiredRole,
                string memory _errorMessage,
                string memory _errorRegister
            ) = abi.decode(
                    _dataArray[i],
                    (bytes32, bool, address, bool, string, string)
                );

            _nftInfo[_nftType] = NftInfo({
                nftType: _nftType,
                canTransfer: _canTransfer,
                scAddress: _scAddress,
                requiredRole: _requiredRole,
                errorMessage: _errorMessage,
                errorRegister: _errorRegister
            });
        }
    }

    function getListOfUuidsPerAccount(address _account)
        external
        view
        returns (uint256[] memory _listOfUuids, bytes32[] memory _listOfTypes)
    {
        _listOfUuids = _ownerToUuids[_account];
        _listOfTypes = new bytes32[](_listOfUuids.length);
        for (uint256 ix = 0; ix < _listOfUuids.length; ix++) {
            _listOfTypes[ix] = _nftTypes[_listOfUuids[ix]];
        }
    }

    function setPachacuyInfoaddress(address _pachacuyInfo)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachacuyInfo = IPachacuyInfo(_pachacuyInfo);
    }

    ///////////////////////////////////////////////////////////////
    ////               ERC1155 STANDARD FUNCTIONS              ////
    ///////////////////////////////////////////////////////////////
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _prefix = newuri;
        _setURI(newuri);
    }

    function tokenURI(uint256 _uuid) public view returns (string memory) {
        require(exists(_uuid), "NFP: Not minted.");

        string memory fileName = ITokenUri(
            pachacuyInfo.getAddressOfNftType(_nftTypes[_uuid])
        ).tokenUri(_prefix, _uuid);

        return bytes(_prefix).length > 0 ? fileName : "";
    }

    function uri(uint256 _uuid) public view override returns (string memory) {
        return tokenURI(_uuid);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Have a look later
    // function mintBatch(
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) public onlyRole(MINTER_ROLE) {
    //     _mintBatch(to, ids, amounts, data);
    // }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
