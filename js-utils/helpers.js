require("dotenv").config();

const { ethers, providers } = require("ethers");

function getImplementation(address) {
  return upgrades.erc1967.getImplementationAddress(address);
}

function decimals() {
  return ethers.BigNumber.from("1000000000000000000");
}

function million() {
  return ethers.BigNumber.from("1000000");
}

function infoHelper(net) {
  // private sale
  var commonPrivateSale = {
    _maxPrivateSaleOne: ethers.BigNumber.from(15)
      .mul(million())
      .mul(decimals())
      .div(10),
    _maxPrivateSaleTwo: ethers.BigNumber.from(15)
      .mul(million())
      .mul(decimals())
      .div(10),
    _exchangeRatePrivateSaleOne: 100,
    _exchangeRatePrivateSaleTwo: 50,
  };
  var privateSaleNet;
  if (net == "TESTNET") {
    privateSaleNet = {
      _busdToken: "0x8301f2213c0eed49a7e28ae4c3e91722919b8b47",
      _walletPrivateSale: process.env.WALLET_FOR_FUNDS,
    };
  } else if (net == "BSCNET") {
    privateSaleNet = {
      _busdToken: "0xe9e7cea3dedca5984780bafc599bd69add087d56",
      _walletPrivateSale: "0x77A45071c532b71Cb4c99126D9A98c1D86276D3A",
    };
  }

  // SwapCuyTokenForPachaCuy
  var commonSwapCuyTokenForPachaCuy = {
    _exchangeRate: 172,
  };

  var swapCuyTokenForPachaCuyNet;
  if (net == "TESTNET") {
    swapCuyTokenForPachaCuyNet = {
      _swapWallet: process.env.WALLET_FOR_FUNDS,
    };
  } else if (net == "BSCNET") {
    swapCuyTokenForPachaCuyNet = {
      _swapWallet: "",
    };
  }

  // Public Sale
  var commonPublicSale = {
    _maxPublicSale: 25,
  };
  var publicSaleNet;

  // Vesting
  var commonVesting = {
    _vestingPeriods: 12,
    _gapBetweenVestingPeriod: 1,
  };

  // PhaseTwoAndX
  var commonPhaseTwoAndX = {
    _capLimitPhaseTwo: ethers.BigNumber.from(6).mul(million()).mul(decimals()),
    _capLimitPhaseX: ethers.BigNumber.from(115)
      .mul(million())
      .mul(decimals())
      .div(10),
  };

  // Pachacuy
  var PachacuyNet;
  if (net == "TESTNET") {
    PachacuyNet = {
      _liquidityPoolWallet: process.env.WALLET_FOR_FUNDS,
    };
  } else if (net == "BSCNET") {
    PachacuyNet = {
      _liquidityPoolWallet: "",
    };
  }

  // Random Number Generator
  var randomNGNet;
  if (net == "BSCTESTNET") {
    randomNGNet = {
      // binance
      vrfCoordinator: "0xa555fC018435bef5A13C6c6870a9d4C11DEC329C",
      linkToken: "0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06",
      keyHash:
        "0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186",
      fee: "100000000000000000",
      capForAirdrop: "30000000000000000000000",
    };
  } else if (net == "RINKEBYTESTNET") {
    randomNGNet = {
      // binance
      vrfCoordinator: "0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B",
      linkToken: "0x01BE23585060835E02B77ef475b0Cc51aA1e0709",
      keyHash:
        "0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311",
      fee: "100000000000000000",
      capForAirdrop: "30000000000000000000000",
    };
  } else if (net == "BSCNET") {
    randomNGNet = {
      _liquidityPoolWallet: "",
    };
  }

  return {
    // private sale
    ...commonPrivateSale,
    ...privateSaleNet,

    // SwapCuyTokenForPachaCuy
    ...commonSwapCuyTokenForPachaCuy,
    ...swapCuyTokenForPachaCuyNet,

    // Public Sale
    ...commonPublicSale,
    // ...publicSaleNet,

    // Vesting
    ...commonVesting,

    // phaseTwoAndX
    ...commonPhaseTwoAndX,

    // Pachacuy
    ...PachacuyNet,

    // role admin
    admin: "0x0000000000000000000000000000000000000000000000000000000000000000",

    // Random Number Generator
    ...randomNGNet,
  };
}

module.exports = {
  getImplementation,
  infoHelper,
};
