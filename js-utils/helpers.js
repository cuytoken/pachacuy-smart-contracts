require("dotenv").config();

const { ethers, providers } = require("ethers");

async function safeAwait(f, msg) {
  try {
    return await f();
  } catch (e) {
    console.error(msg, e);
  }
}

function getImplementation(contract) {
  if (typeof contract == "string") {
    return upgrades.erc1967.getImplementationAddress(contract);
  }
  if (!!contract.address) {
    return upgrades.erc1967.getImplementationAddress(contract.address);
  }
  return null;
}

function decimals() {
  return ethers.BigNumber.from("1000000000000000000");
}

function million() {
  return ethers.BigNumber.from("1000000");
}

const updater_role = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("UPDATER_ROLE")
);

const rng_generator = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("RNG_GENERATOR")
);

const upgrader_role = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("UPGRADER_ROLE")
);

const pauser_role = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("PAUSER_ROLE")
);

const uri_setter_role = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("URI_SETTER_ROLE")
);

const minter_role = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("MINTER_ROLE")
);

var roles = {
  updater_role,
  upgrader_role,
  pauser_role,
  uri_setter_role,
  minter_role,
  rng_generator,
};

// 2
var FENOMENO = [
  1, 10, 1002, 1004, 1005, 1008, 1011, 1012, 102, 1021, 1022, 1025, 1029, 103,
  1031, 1034, 1038, 1039, 1040, 1057, 1069, 1091, 1093, 1096, 1100, 1101, 111,
  1118, 1126, 1129, 1138, 1140, 1145, 1146, 1156, 1157, 1160, 1167, 1183, 1186,
  1187, 1188, 1205, 1213, 1228, 1230, 1239, 1240, 125, 1253, 1255, 1258, 1262,
  1271, 1273, 1274, 1278, 1280, 1289, 1296, 1306, 131, 1310, 1325, 1328, 1344,
  1347, 1357, 1358, 1359, 136, 1367, 1371, 1386, 1389, 1392, 1396, 1397, 1398,
  1407, 1414, 1416, 1417, 1419, 1420, 1421, 1424, 1425, 1438, 144, 1446, 1447,
  1449, 1453, 1457, 1459, 146, 1468, 147, 1471, 1476, 1477, 1482, 1486, 149,
  1493, 1507, 1508, 1510, 1514, 1525, 1536, 1544, 1557, 1560, 1574, 1575, 1576,
  1579, 1606, 161, 1615, 1623, 1637, 1647, 165, 1650, 1654, 1655, 1657, 166,
  1661, 1666, 1667, 1671, 1677, 1684, 1688, 169, 1700, 1704, 1723, 1724, 1736,
  1737, 1738, 1741, 1744, 1748, 1749, 1756, 1760, 1764, 1769, 1772, 1778, 1788,
  1806, 1807, 1809, 1812, 182, 1859, 1860, 1867, 1881, 1883, 1892, 1895, 1896,
  1904, 1908, 1911, 1912, 1919, 192, 1924, 1925, 1937, 1938, 1947, 1958, 1971,
  1977, 1979, 1984, 1987, 1989, 1992, 1994, 1995, 1999, 205, 213, 217, 226, 23,
  230, 235, 240, 243, 244, 245, 250, 256, 258, 260, 265, 271, 273, 298, 300,
  310, 311, 315, 32, 323, 33, 332, 337, 342, 352, 353, 361, 368, 371, 376, 378,
  38, 39, 392, 393, 395, 397, 401, 41, 410, 413, 42, 420, 421, 422, 424, 427,
  428, 432, 433, 434, 452, 46, 462, 468, 47, 477, 478, 480, 49, 490, 493, 494,
  497, 499, 504, 509, 514, 515, 520, 523, 528, 539, 540, 542, 545, 546, 549, 56,
  563, 568, 57, 571, 572, 577, 581, 591, 593, 596, 599, 603, 61, 618, 620, 621,
  623, 630, 636, 638, 640, 652, 654, 668, 669, 671, 673, 676, 679, 680, 693,
  698, 699, 70, 700, 706, 71, 711, 718, 721, 722, 727, 733, 741, 746, 765, 77,
  777, 778, 78, 781, 782, 788, 791, 8, 801, 804, 810, 811, 820, 825, 844, 860,
  867, 870, 878, 882, 884, 885, 889, 89, 898, 9, 905, 909, 911, 913, 914, 916,
  918, 92, 922, 924, 927, 938, 941, 943, 944, 945, 949, 951, 953, 954, 956, 957,
  963, 965, 969, 97, 973, 982, 989, 99, 999,
];

var MISTICO = [
  // 3
  101, 1043, 1068, 1092, 1119, 1123, 1125, 1171, 1290, 1291, 1340, 1455, 1467,
  1478, 1496, 1501, 1543, 1569, 16, 1612, 1616, 1621, 168, 1693, 1705, 1726,
  1729, 176, 178, 1785, 1838, 185, 1914, 1931, 1944, 1956, 1960, 1981, 215, 228,
  263, 277, 282, 312, 326, 354, 380, 384, 402, 411, 487, 489, 50, 503, 508, 533,
  544, 557, 559, 580, 587, 601, 619, 624, 648, 687, 697, 7, 702, 719, 747, 80,
  807, 831, 874, 920, 930, 933, 94, 96, 961,
];

// 4
var LEGENDARIO = [1063, 108, 1080, 1182, 1284, 1578, 1586, 1626, 221, 26, 349];

// 5
var SUPREMO = [1403];

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
  if (net == "BSCTESTNET") {
    privateSaleNet = {
      _busdToken: "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee",
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

  var pachacuyNftCollection;
  if (net == "BSCTESTNET") {
    pachacuyNftCollection = {
      _busdToken: "0x8F1C7AAf8EC93A500657aEc7C030d392fd4cAA13",
      _tokenName: "Pachacuy Moche",
      _tokenSymbol: "PCUYMOCHE",
      _maxSupply: 20,
      _nftCurrentPrice: ethers.utils.parseEther("30"),
      _baseUri: "ipfs://QmPHmBXbyx8rzTtQ26o1VTkM5fsXM8ZJauCcy4SULozg45/",
    };
  } else if (net == "BSCNET") {
    pachacuyNftCollection = {
      _busdToken: "0xe9e7cea3dedca5984780bafc599bd69add087d56",
      _tokenName: "Pachacuy Moche",
      _tokenSymbol: "PCUYMOCHE",
      _maxSupply: 2000,
      _nftCurrentPrice: ethers.utils.parseEther("30"),
      _baseUri: "ipfs://QmPHmBXbyx8rzTtQ26o1VTkM5fsXM8ZJauCcy4SULozg45/",
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

    // NFT
    ...pachacuyNftCollection,

    // roles
  };
}

module.exports = {
  ...roles,
  getImplementation,
  infoHelper,
  FENOMENO,
  MISTICO,
  LEGENDARIO,
  safeAwait,
};
