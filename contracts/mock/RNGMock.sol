// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRNMock {
    function isRequestComplete(address _account)
        external
        view
        returns (bool isCompleted);

    function requestRandomNumber(address _account)
        external
        returns (uint32 lockBlock);
}

interface IAirdrop {
    function fulfillRandomness(address _account, uint256 randomness) external;
}

contract RNGMock is IRNMock {
    IAirdrop airdrop;

    mapping(address => bool) requestsCompleted;

    function random() private view returns (uint256) {
        uint256 ans = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        return (ans % 500) + 1;
    }

    function requestRandomNumber(address _account)
        external
        override
        returns (uint32 lockBlock)
    {
        requestsCompleted[_account] = false;
        airdrop.fulfillRandomness(_account, random());
        requestsCompleted[_account] = true;
        return 0;
    }

    function isRequestComplete(address _account)
        external
        view
        override
        returns (bool isCompleted)
    {
        isCompleted = requestsCompleted[_account];
    }

    function setContractToReceiveRandomNG(
        address contractReceivingRandomAddress
    ) public {
        airdrop = IAirdrop(contractReceivingRandomAddress);
    }
}
