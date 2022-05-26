// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPachacuyInfo {
    function totalFood() external returns (uint256);

    function pricePerFood() external returns (uint256);

    function chakraAddress() external returns (address);

    function wiracochaAddress() external returns (address);

    function tatacuyAddress() external returns (address);

    function poolRewardAddress() external returns (address);

    function hatunWasiAddress() external returns (address);

    function purchaseACAddress() external returns (address);

    function pachaCuyTokenAddress() external returns (address);

    function misayWasiAddress() external returns (address);

    function nftProducerAddress() external returns (address);

    function guineaPigAddress() external returns (address);

    function randomNumberGAddress() external returns (address);

    function binarySearchAddress() external returns (address);

    //////////////////////////////////////////////////////////////////
    ///                          TAXES/FEES                        ///
    //////////////////////////////////////////////////////////////////

    function raffleTax() external returns (uint256);

    function purchaseTax() external returns (uint256);

    //////////////////////////////////////////////////////////////////
    ///                  BUSINESS PRICES (BUSD)                    ///
    //////////////////////////////////////////////////////////////////
    function chakraPrice() external returns (uint256);

    function pachaPrice() external returns (uint256);

    function qhatuWasiPrice() external returns (uint256);

    function misayWasiPrice() external returns (uint256);

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
}
