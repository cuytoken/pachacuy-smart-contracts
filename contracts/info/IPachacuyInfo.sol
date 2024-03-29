// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITokenUri {
    function tokenUri(string memory _prefix, uint256 _uuid)
        external
        view
        returns (string memory);
}

interface IPachacuyInfo {
    function totalFood() external returns (uint256);

    function pricePerFood() external returns (uint256);

    function chakraAddress() external view returns (address);

    function wiracochaAddress() external view returns (address);

    function tatacuyAddress() external view returns (address);

    function bizWalletAddress() external view returns (address);

    function hatunWasiAddress() external view returns (address);

    function purchaseACAddress() external view returns (address);

    function pachaCuyTokenAddress() external view returns (address);

    function misayWasiAddress() external view returns (address);

    function nftProducerAddress() external view returns (address);

    function guineaPigAddress() external view returns (address);

    function randomNumberGAddress() external view returns (address);

    function binarySearchAddress() external view returns (address);

    function pachaAddress() external view returns (address);

    function qhatuWasiAddress() external view returns (address);

    //////////////////////////////////////////////////////////////////
    ///                          TAXES/FEES                        ///
    //////////////////////////////////////////////////////////////////

    function raffleTax() external returns (uint256);

    function purchaseTax() external returns (uint256);

    function qhatuWasiTax() external returns (uint256);

    //////////////////////////////////////////////////////////////////
    ///                  BUSINESS PRICES (BUSD)                    ///
    //////////////////////////////////////////////////////////////////
    function getPriceInPcuy(bytes memory _type) external returns (uint256);

    //////////////////////////////////////////////////////////////////
    ///                       EXCHANGE RATE                        ///
    //////////////////////////////////////////////////////////////////
    function exchangeRatePcuyToSami() external returns (uint256);

    function exchangeRateBusdToPcuy() external returns (uint256);

    function convertBusdToPcuy(uint256 _busdAmount)
        external
        returns (uint256 _pacuyAmount);

    function convertPcuyToSami(uint256 _pcuyAmount)
        external
        returns (uint256 _samiPoints);

    function convertSamiToPcuy(uint256 _samiAmount)
        external
        returns (uint256 _pcuyAmount);

    //////////////////////////////////////////////////////////////////
    ///                      ADDRESS RETRIEVAL                     ///
    //////////////////////////////////////////////////////////////////

    function getAddressOfNftType(bytes32 _type) external view returns (address);

    // tokens
    function updateWhitelist(
        address _account,
        bool _included_,
        uint256 _id
    ) external;

    function isWhiteListed(uint256 _id) external view returns (address, bool);
}
