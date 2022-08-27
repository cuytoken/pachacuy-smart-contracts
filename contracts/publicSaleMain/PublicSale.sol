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
////                                               PCUY Public Sale                                              ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777SenderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC1820RegistryUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../tokenomics/IVesting.sol";

/// @custom:security-contact lee@cuytoken.com
contract PublicSalePcuy is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    IERC777RecipientUpgradeable,
    IERC777SenderUpgradeable,
    UUPSUpgradeable
{
    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY =
        IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Vesting smart contract
    IVesting public vestingSC;

    // pachacuy token
    IERC777Upgradeable public pachaCuyToken;

    // usdc token
    IERC20 public usdcToken;

    // rate from USDC to PCUY
    uint256 public exchangeRateUsdcToPcuy;

    // wallet address for funds
    address public walletForFunds;

    // total USDC raised
    uint256 public totalUsdcRaised;

    // total PCUY sold
    uint256 public totalPcuySold;

    // total extra PCUY for vesting
    uint256 public totalPcuyVesting;

    event TokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    event TokensSent(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    event PcuyPurchased(
        address purchaser,
        uint256 usdcAmount,
        uint256 pcuyPurchased,
        uint256 pcuyVesting
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

        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_SENDER_INTERFACE_HASH,
            address(this)
        );

        totalUsdcRaised = 0;
        totalPcuySold = 0;
        totalPcuyVesting = 0;
    }

    //////////////////////////////////////////////////////////////////////////
    /////////////////////////// Purchase Process /////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    function purchasePcuyWithUsdc(uint256 _usdcAmount) external whenNotPaused {
        // verify if approved
        uint256 usdcAllowance = usdcToken.allowance(
            _msgSender(),
            address(this)
        );
        require(
            usdcAllowance >= _usdcAmount,
            "Public Sale: Not enough USDC allowance"
        );

        // verify usdc balance
        uint256 usdcBalance = usdcToken.balanceOf(_msgSender());
        require(
            usdcBalance >= _usdcAmount,
            "Public Sale: Not enough USDC balance"
        );

        // transfer usdc to funds wallet
        bool success = usdcToken.transferFrom(
            _msgSender(),
            walletForFunds,
            _usdcAmount
        );
        require(success, "Public Sale: Failed to transfer USDC");
        totalUsdcRaised += _usdcAmount;

        // total PCUY to transfer
        uint256 pcuyToTransfer = _usdcAmount * exchangeRateUsdcToPcuy;

        // verify PCUY balance
        uint256 pcuyBalance = pachaCuyToken.balanceOf(address(this));
        require(
            pcuyBalance >= pcuyToTransfer,
            "Public Sale: Not enough PCUY to sell"
        );

        // transfer PCUY to customer
        pachaCuyToken.send(_msgSender(), pcuyToTransfer, "");
        totalPcuySold += pcuyToTransfer;

        // Vesting
        uint256 pcuyExtraVesting = (pcuyToTransfer * 15) / 100;
        totalPcuyVesting += pcuyExtraVesting;
        uint256 vestingPeriods = 10;
        uint256 releaseDay = block.timestamp;
        string memory roleOfAccount = "MARKETING";
        vestingSC.createVestingSchema(
            _msgSender(),
            pcuyExtraVesting,
            vestingPeriods,
            releaseDay,
            roleOfAccount
        );

        emit PcuyPurchased(
            _msgSender(),
            _usdcAmount,
            pcuyToTransfer,
            pcuyExtraVesting
        );
    }

    //////////////////////////////////////////////////////////////////////////
    ///////////////////////////  Helper Function  ////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    function setPachaCuyAddress(address _pachaCuyTokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken = IERC777Upgradeable(_pachaCuyTokenAddress);
    }

    function setVestingSCAddress(address _vestingSCAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vestingSC = IVesting(_vestingSCAddress);
    }

    function setUsdcTokenAddress(address _usdcTokenAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        usdcToken = IERC20(_usdcTokenAddress);
    }

    function setExchangeRateUsdcToPcuy(uint256 _exchangeRateUsdcToPcuy)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        exchangeRateUsdcToPcuy = _exchangeRateUsdcToPcuy;
    }

    function setWalletForFunds(address _walletForFunds)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        walletForFunds = _walletForFunds;
    }

    function withdrawRemainingPcuy(address _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pachaCuyToken.send(_to, pachaCuyToken.balanceOf(address(this)), "");
    }

    //////////////////////////////////////////////////////////////////////////
    ///////////////////////////  Standard Function  //////////////////////////
    //////////////////////////////////////////////////////////////////////////

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensReceived(operator, from, to, amount, userData, operatorData);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensSent(operator, from, to, amount, userData, operatorData);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
}
