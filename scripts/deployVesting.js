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

// reading data from csv file
var file = "vestingData/holders.csv";
var data = require("fs").readFileSync(file, "utf8");
data = data.split("\r\n");
var _accounts = [];
var _fundsToVestArray = [];
var _vestingPeriods = [];
var _releaseDays = [];
var _roleOfAccounts = [];
data.forEach((row) => {
  var line = row.split(",");
  _accounts.push(line[0]);
  _fundsToVestArray.push(pe(line[1]));
  _vestingPeriods.push(Number(line[2]));
  _releaseDays.push(1657843200);
  _roleOfAccounts.push(line[3]);
});

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

  // var VestingAddress = "0xf791F2434c8024FF407771D198aCbcc2668E170e";
  // var Vesting = await gcf("Vesting");
  // var vesting = await Vesting.attach(VestingAddress);
  // var PachaCuyTokenAddress = "0x450201A447C00bca8d6f762605066EFA37CAba38";
  // var PachaCuyToken = await gcf("PachaCuyToken");
  // var pachaCuyToken = await PachaCuyToken.attach(PachaCuyTokenAddress);

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
  var mktTkns = pe(String(5 * 1000000));
  var c = [
    hldrTkns, // * HOLDER_CUY_TOKEN     -> 1
    pe(String(1.5 * 1000000)), // * PRIVATE_SALE_1       -> 1.5
    pe(String(0.6 * 1000000)), // * PRIVATE_SALE_2       -> 0.6
    pe(String(1.4 * 1000000)), // * AIRDROP              -> 1.4
    pe(String(10 * 1000000)), // * PACHACUY_TEAM        -> 10
    pe(String(5 * 1000000)), // * PARTNER_ADVISOR      -> 5
    mktTkns, // * MARKETING            -> 5
  ];
  // Vesting
  var ves = vesting;
  var pcuyA = pachaCuyToken.address;
  await executeSet(ves, "settingVestingStateStructs", [r, c], "ves 001");
  await executeSet(ves, "setPachaCuyAddress", [pcuyA], "ves 002");

  var vt = vesting;
  var cm = "createVestingSchemaBatch";
  // part 1 - 50
  var _a = _accounts.slice(0, 50);
  var _f = _fundsToVestArray.slice(0, 50);
  var _v = _vestingPeriods.slice(0, 50);
  var _d = _releaseDays.slice(0, 50);
  var _r = _roleOfAccounts.slice(0, 50);
  await executeSet(vt, cm, [_a, _f, _v, _d, _r], "Part 1");
  console.log("Finish part 1");

  // part 51 - 100
  var _a = _accounts.slice(50, 100);
  var _f = _fundsToVestArray.slice(50, 100);
  var _v = _vestingPeriods.slice(50, 100);
  var _d = _releaseDays.slice(50, 100);
  var _r = _roleOfAccounts.slice(50, 100);
  await executeSet(vt, cm, [_a, _f, _v, _d, _r], "Part 2");
  console.log("Finish part 2");

  // part 101 - 150
  var _a = _accounts.slice(100, 150);
  var _f = _fundsToVestArray.slice(100, 150);
  var _v = _vestingPeriods.slice(100, 150);
  var _d = _releaseDays.slice(100, 150);
  var _r = _roleOfAccounts.slice(100, 150);
  await executeSet(vt, cm, [_a, _f, _v, _d, _r], "Part 3");
  console.log("Finish part 3");

  // part 151 - 191
  var parts = 41;
  var _a = _accounts.slice(150, 191);
  var _f = _fundsToVestArray.slice(150, 191);
  var _v = _vestingPeriods.slice(150, 191);
  var _d = _releaseDays.slice(150, 191);
  var _r = _roleOfAccounts.slice(150, 191);
  await executeSet(vt, cm, [_a, _f, _v, _d, _r], "Part 4");
  console.log("Finish part 4");

  // Verify smart contracts
  return;
  if (!process.env.HARDHAT_NETWORK) return;
  var MUMBAI_POOL_REWARDS = "0x51882A4D40f93889d3f096CBF751173b65701b6d";
  await verify(vestingImp, "Vesting");
  await verify(pachaCuyToken.address, "PCUY", [
    vesting.address,
    owner.address,
    MUMBAI_POOL_REWARDS,
    owner.address,
    owner.address,
    [owner.address],
  ]);

  var add = "0xE007f0be183711DE89f6Fee70DfBB0DcBB9fC9CE";
  // await vesting.grantRole(manager_vesting, add);
}

async function setUpVesting() {
  var VestingAddress = "0xC4db798fB770e97f920860E9E342C537EA3940F0";
  var Vesting = await gcf("Vesting");
  var vesting = await Vesting.attach(VestingAddress);
  // 1656979200 - 5 July 2022 0:00:00
  // 1657065600 - 6 July 2022 0:00:00
  // 1657152000 - 7 July 2022 0:00:00
  // var add = "0xA6B2Fa18d3e746D3012dAbc21e63BcC35E638897";
  var add = "0xC345C8653cfc721Bf832b8316565e2624A2565fc";
  // var add = "0xE007f0be183711DE89f6Fee70DfBB0DcBB9fC9CE";

  var d = [add, pe("1000"), 5, 1656979200, "MARKETING"];
  await vesting.createVestingSchema(...d);
  var d = [add, pe("400000"), 5, 1657065600, "MARKETING"];
  await vesting.createVestingSchema(...d);
  var d = [add, pe("1000000"), 5, 1657152000, "MARKETING"];
  await vesting.createVestingSchema(...d);

  // var add = "0xC345C8653cfc721Bf832b8316565e2624A2565fc";
  var add = "0xE007f0be183711DE89f6Fee70DfBB0DcBB9fC9CE";

  var d = [add, pe("1000"), 5, 1656979200, "MARKETING"];
  await vesting.createVestingSchema(...d);
  var d = [add, pe("400000"), 5, 1657065600, "MARKETING"];
  await vesting.createVestingSchema(...d);
  var d = [add, pe("1000000"), 5, 1657152000, "MARKETING"];
  await vesting.createVestingSchema(...d);

  // await vesting.grantRole(manager_vesting, add);
  console.log("done");
}

main()
  // setUpVesting()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
