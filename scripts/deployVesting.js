const { upgrades, ethers, hardhatArguments } = require("hardhat");
const hre = require("hardhat");

const {
  safeAwait,
  getImplementation,
  executeSet,
  verify,
  manager_vesting,
} = require("../js-utils/helpers");
var pe = ethers.utils.parseEther;

// const NETWORK = "BSCNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var bn = ethers.BigNumber.from;
async function main() {
  var [owner] = await ethers.getSigners();
  if (process.env.HARDHAT_NETWORK) upgrades.silenceWarnings();

  const Vesting = await gcf("Vesting");
  const vesting = await dp(Vesting, [], {
    kind: "uups",
  });
  await vesting.deployed();
  console.log("Vesting Proxy:", vesting.address);
  var vestingImp = await getImplementation(vesting);
  console.log("Vesting Imp:", vestingImp);

  /**
   * Pachacuy Token PCUY
   * 1. Gather all operators and pass it to the initialize
   */
  var PachaCuyToken, pachaCuyToken, pachacuyTokenImp;
  if (process.env.HARDHAT_NETWORK) {
    PachaCuyToken = await gcf("PachaCuyToken");
    pachaCuyToken = await PachaCuyToken.deploy(
      vesting.address,
      owner.address,
      owner.address,
      owner.address,
      owner.address,
      [owner.address]
    );
    await pachaCuyToken.deployed();
    console.log("PachaCuyToken:", pachaCuyToken.address);
  }

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Finish Setting up Smart Contracts");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  var r = [
    "HOLDER_CUY_TOKEN",
    "PRIVATE_SALE_1",
    "PRIVATE_SALE_2",
    "AIRDROP",
    "PACHACUY_TEAM",
    "PARTNER_ADVISOR",
    "MARKETING",
  ];

  var hldrTkns = pe(String(1 * 1000000));
  var mktTkns = pe(String(10 * 1000000));
  var c = [
    hldrTkns, // * HOLDER_CUY_TOKEN     -> 1
    pe(String(1.5 * 1000000)), // * PRIVATE_SALE_1       -> 1.5
    pe(String(0.6 * 1000000)), // * PRIVATE_SALE_2       -> 0.6
    pe(String(1.2 * 1000000)), // * AIRDROP              -> 1.2
    pe(String(12 * 1000000)), // * PACHACUY_TEAM        -> 12
    pe(String(10 * 1000000)), // * PARTNER_ADVISOR      -> 10
    mktTkns, // * MARKETING            -> 10
  ];
  // Vesting
  var ves = vesting;
  var pcuyA = pachaCuyToken.address;
  await executeSet(ves, "settingVestingStateStructs", [r, c], "ves 001");
  await executeSet(ves, "setPachaCuyAddress", [pcuyA], "ves 002");

  // Verify smart contracts
  if (!process.env.HARDHAT_NETWORK) return;

  await verify(vestingImp, "Vesting");
  await verify(pachaCuyToken.address, "PCUY", [
    vesting.address,
    owner.address,
    owner.address,
    owner.address,
    owner.address,
    [owner.address],
  ]);
}

async function setUpVestingStruct() {
  var VestingAddress = "0xD5b8EdA458Ff2a9B2Cb4261194aA4d5Abd7Fb3bF";
  var Vesting = await gcf("Vesting");
  var vesting = await Vesting.attach(VestingAddress);
  var hldrTkns = pe(String(1 * 1000000));
  var mktTkns = pe(String(10 * 1000000));
  var r = [
    "HOLDER_CUY_TOKEN",
    "PRIVATE_SALE_1",
    "PRIVATE_SALE_2",
    "AIRDROP",
    "PACHACUY_TEAM",
    "PARTNER_ADVISOR",
    "MARKETING",
  ];
  var c = [
    hldrTkns, // * HOLDER_CUY_TOKEN     -> 1
    pe(String(1.5 * 1000000)), // * PRIVATE_SALE_1       -> 1.5
    pe(String(0.6 * 1000000)), // * PRIVATE_SALE_2       -> 0.6
    pe(String(1.2 * 1000000)), // * AIRDROP              -> 1.2
    pe(String(12 * 1000000)), // * PACHACUY_TEAM        -> 12
    pe(String(10 * 1000000)), // * PARTNER_ADVISOR      -> 10
    mktTkns, // * MARKETING            -> 10
  ];
  // Vesting
  var ves = vesting;
  await executeSet(ves, "settingVestingStateStructs", [r, c], "ves 001");
}

async function setUpVesting() {
  var VestingAddress = "0xD5b8EdA458Ff2a9B2Cb4261194aA4d5Abd7Fb3bF";
  var Vesting = await gcf("Vesting");
  var vesting = await Vesting.attach(VestingAddress);
  // 1656979200 - 5 July 2022 0:00:00
  // 1657065600 - 6 July 2022 0:00:00
  // 1657152000 - 7 July 2022 0:00:00
  var add = "0x45f27ca040d193fC8B40Fe2F5De13889cDb741A1";

  var d = [add, pe("1000"), 5, 1656979200, "MARKETING"];
  await vesting.createVestingSchema(...d);
  var d = [add, pe("400000"), 5, 1657065600, "MARKETING"];
  await vesting.createVestingSchema(...d);
  var d = [add, pe("1000000"), 5, 1657152000, "MARKETING"];
  await vesting.createVestingSchema(...d);

  await vesting.grantRole(manager_vesting, add);
}

// main()
setUpVesting()
  // setUpVestingStruct()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
