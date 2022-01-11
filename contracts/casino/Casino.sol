// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../random/IRandomGenerator.sol";

/// @custom:security-contact lee@cuytoken.com
contract Casino is
    IRandomGenerator,
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable
{
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ENTREPRENEUR_ROLE = keccak256("ENTREPRENEUR_ROLE");

    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 uniqueCasinoContestId;
    IERC20Upgradeable public pachacuyToken;
    IRandomGenerator public randomGenerator;

    bytes32 requestId;
    uint256 randomness;
    
    /**
     * @param _casinoOwner: Creator of the Casino contest
     * @param keyHash: Hash to be used for minting tickets for each casino
     * @param contestName: Name of the Casino contest created
     * @param timestamp: Time at which the Casino contest created
     * @param limitedParticipants: Boolean that indicates whether it's a limited-participant contest
     * @param amountOfParticipants: In case it's a limited-participant contest, indicates its limit amount
     * @param currentlyActive: Shows if this particular Casino contest is currently running
     * @param participants: Holds the list of participants for a particular Casino Contest
     * @param ticketPrice: Price to be paid in PACHACUY tokens to enter the Casino Contest
     */
    struct CasinoInfoStruct {
        address casinoOwner;
        uint256 uniqueCasinoContestId;
        string contestName;
        uint256 timestamp;
        uint128 amountOfParticipants;
        bool currentlyActive;
        address[] participants;
        uint256 ticketPrice;
    }

    /**
     * @dev IDs of casinos created per each 'Entrepreneur' role mappend to address.
     * IDs are positive integers (0, 1, ...)
     * Entrepreneur's address => ID of each casino created
     */
    mapping(address => uint128) casinosCreatedPerEntrepreneur;

    /**
     * @dev Information about each Casino crated mapped to a particular it which is mapped to an address
     * Casino's information is a struct with several properties - see CasinoInfo struct
     * Entrepreneur's address => ID of each casino created => CasinoInfo struct
     */
    mapping(address => mapping(uint128 => CasinoInfoStruct)) CasinoInfo;

    /**
     * Event fired when a Casino contest is created
     * @param _msgSender: Creator of the casino contest
     * @param uniqueCasinoContestId: Unique ID generated for a Casino Contest
     * @param timestamp: Time at which the casino contest was created
     * @param contestName: Name of the casino contest
     */
    event CasinoCreated(
        address _msgSender,
        uint256 uniqueCasinoContestId,
        uint256 timestamp,
        string contestName
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _pachaCuyTokenAddress,
        address _randomGeneratorAddress
    ) public initializer {
        __ERC1155_init(
            "https://cuytoken.com/pachacuy-game/api/token/{id}.json"
        );
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(URI_SETTER_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

        pachacuyToken = IERC20Upgradeable(_pachaCuyTokenAddress);
        randomGenerator = IRandomGenerator(_randomGeneratorAddress);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        public
        override
    {
        // this is the callback for the random generated number
        requestId = _requestId;
        randomness = _randomness;
    }

    function getRandomNumber() public override returns (bytes32 _requestId) {
        _requestId = randomGenerator.getRandomNumber();
        requestId = _requestId;
        return _requestId;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @notice Assigns the 'Entrepreneur' role to an account. An 'Entrepreneur' is able to own lands and purchase assets
     * @dev _account changes a to 'Entrepreneur' role. Only callable by Admin
     * @param _account to be upgrade to 'Entrepreneur'
     */
    function upgradeRoleToEntrepreneur(address _account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(ENTREPRENEUR_ROLE, _account);
    }

    /**
     * @notice Creates a unique Casino Contest ID.
     * @dev Used for creating a specific ticket for a Casino Contest
     * @return Returns a unique Casino Contest ID to be used as identifier in a contest
     */
    function generateUniqueCasinoContestId() internal returns (uint256) {
        return uniqueCasinoContestId++;
    }

    /**
     * @notice Sends a Casino contest ticket to one person
     * @dev Used for creating and sending a specific ticket for a Casino Contest
     * @param _contestPos is 1 or 2: each Entrepreneur could run two contest which are stored in either position 1 or 2
     * @param _account is the address of the person receiving the ticket
     */
    function sendTicketOneByOne(uint128 _contestPos, address _account)
        public
        onlyRole(ENTREPRENEUR_ROLE)
    {
        require(
            CasinoInfo[_msgSender()][_contestPos].currentlyActive,
            "Casino: This Casino contest is not running"
        );

        uint256 _uniqueCasinoContestId = CasinoInfo[_msgSender()][_contestPos]
            .uniqueCasinoContestId;

        uint256 balanceTickets = balanceOf(_account, _uniqueCasinoContestId);
        require(
            balanceTickets == 0,
            "Casino: This account has a ticket already"
        );

        mint(_account, _uniqueCasinoContestId, 1, "");
    }

    /**
     * @notice Sends several Casino contest tickets to several people, all at once
     * @dev Used for creating and sending several specific ticket for a Casino Contest
     * @param _contestPos is 1 or 2: each Entrepreneur could run two contest which are stored in either position 1 or 2
     * @param _addresses is the the list of addresses of the people receiving the tickets
     */
    function sendTicketsInBatch(
        uint128 _contestPos,
        address[] memory _addresses
    ) public onlyRole(ENTREPRENEUR_ROLE) {
        require(
            CasinoInfo[_msgSender()][_contestPos].currentlyActive,
            "Casino: This Casino contest is not running"
        );

        uint256 _uniqueCasinoContestId = CasinoInfo[_msgSender()][_contestPos]
            .uniqueCasinoContestId;
        mint(_msgSender(), _uniqueCasinoContestId, _addresses.length, "");

        // transfer to all addresses from msg.sender
        uint128 ix = 0;
        uint256 balanceTickets;
        while (ix < _addresses.length) {
            balanceTickets = balanceOf(_addresses[ix], _uniqueCasinoContestId);
            if (balanceTickets == 0) {
                safeTransferFrom(
                    _msgSender(),
                    _addresses[ix],
                    _uniqueCasinoContestId,
                    1,
                    ""
                );
                ix++;
            }
        }
    }

    /**
     * @notice Creates a Casino Contest for giving away certain prizes
     * @dev _account changes a to 'Entrepreneur' role. Only callable by Admin
     * @param _contestName: Name of Casino contest to create
     * @param _ticketPrice: Price to be paid in PACHACUY tokens to enter the Casino Contest
     */
    function createCasinoContest(
        string memory _contestName,
        uint256 _ticketPrice
    ) public onlyRole(ENTREPRENEUR_ROLE) {
        uint128 numberOfCasinosCreated = casinosCreatedPerEntrepreneur[
            _msgSender()
        ];

        require(
            numberOfCasinosCreated < 2,
            "Casino: Cannot create more than 2 Casino contest at a time."
        );

        // contestPos is [1, 2]: only possible to run two contests at a time
        uint128 contestPos = CasinoInfo[_msgSender()][1].currentlyActive
            ? 2
            : 1;
        casinosCreatedPerEntrepreneur[_msgSender()]++;
        uint256 _uniqueCasinoContestId = generateUniqueCasinoContestId();
        CasinoInfo[_msgSender()][contestPos] = CasinoInfoStruct(
            _msgSender(),
            _uniqueCasinoContestId,
            _contestName,
            block.timestamp,
            0,
            true,
            new address[](0),
            _ticketPrice
        );

        emit CasinoCreated(
            _msgSender(),
            _uniqueCasinoContestId,
            block.timestamp,
            _contestName
        );
    }

    /**
     * @notice Allows a Guinea Pig to enter a Casino Contest paying a fee in Pachacuy Token
     * @dev A Casino Contest owner cannot enter his own contest
     * @param _casinoOwner Address of the Casino Contest Owner
     * @param _contestPos is 1 or 2: each Entrepreneur could run two contest which are stored in either position 1 or 2
     */
    function enterCasinoContest(address _casinoOwner, uint128 _contestPos)
        public
    {
        require(
            CasinoInfo[_casinoOwner][_contestPos].casinoOwner != _casinoOwner,
            "Casino: Casino Owner cannot Enter the contest."
        );

        require(
            CasinoInfo[_casinoOwner][_contestPos].currentlyActive,
            "Casino: This Casino contest is not running"
        );

        uint256 _ticketPrice = CasinoInfo[_casinoOwner][_contestPos]
            .ticketPrice;
        require(
            _ticketPrice <= pachacuyToken.balanceOf(_msgSender()),
            "Casino: Not enough balance to enter the Casino Contest"
        );

        pachacuyToken.safeTransferFrom(
            _msgSender(),
            _casinoOwner,
            _ticketPrice
        );

        CasinoInfo[_casinoOwner][_contestPos].amountOfParticipants++;
        CasinoInfo[_casinoOwner][_contestPos].participants.push(_msgSender());
    }

    function chooseWinnerCasinoContest() public {}

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

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
