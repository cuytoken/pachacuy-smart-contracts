// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../casino/ICasinoCallback.sol";

contract RandomGenerator is VRFConsumerBase, AccessControl {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    address public casinoContractAddress;

    ICasinoCallback public casinoCallback;

    bytes32 public constant BACKEND_ADMIN_ROLE =
        keccak256("BACKEND_ADMIN_ROLE");

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */

    constructor(address _casinoContractAddress)
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088 // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)

        grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(DEFAULT_ADMIN_ROLE, _casinoContractAddress);
        casinoCallback = ICasinoCallback(_casinoContractAddress);
    }

    /**
     * Requests randomness
     */
    function getRandomNumber()
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
        casinoCallback.fulfillRandomness(requestId, randomness);
    }

    function setCasinoAddress(address _casinoAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        casinoContractAddress = _casinoAddress;
        casinoCallback = ICasinoCallback(_casinoAddress);
    }
}
