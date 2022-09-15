const { BigNumber } = require("ethers");
const { upgrades, ethers, hardhatArguments } = require("hardhat");
const hre = require("hardhat");

const {
  safeAwait,
  getImplementation,
  infoHelper,
  updater_role,
  upgrader_role,
  pauser_role,
  uri_setter_role,
  minter_role,
  rng_generator,
  money_transfer,
  game_manager,
  pachacuyInfoForGame,
  verify,
  executeSet,
  businessesPrice,
  businessesKey,
  toBytes32,
  callSequenceAgnostic,
  manager_vesting,
} = require("../js-utils/helpers");
var { callSequence } = require("../js-utils/helpterTesting");

var pe = ethers.utils.parseEther;
var polygon = true;
var rinkeby = false;
var nftData;

var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var bn = ethers.BigNumber.from;

async function main() {
  var [owner] = await ethers.getSigners();
  if (process.env.HARDHAT_NETWORK) upgrades.silenceWarnings();
  var Vesting,
    vesting,
    PachaCuyToken,
    pachaCuyToken,
    PublicSalePcuy,
    publicSalePcuy,
    Usdc,
    usdc;

  /**
   * VESTING
   * 1. Gives manager_vesting to public sale sc
   */
  // Vesting = await gcf("Vesting");
  // vesting = await dp(Vesting, [], {
  //   kind: "uups",
  // });
  // await vesting.deployed();
  // console.log("Vesting Proxy:", vesting.address);
  // var vestingImp = await getImplementation(vesting);
  // console.log("Vesting Imp:", vestingImp);
  var VestingAddress = "0x39400fA10eAd44E551d3a76Fb1F1540618141730";
  Vesting = await gcf("Vesting");
  vesting = await Vesting.attach(VestingAddress);

  /**
   * Pachacuy Token PCUY
   * 1. Gather all operators and pass it to the initialize
   */

  // PachaCuyToken = await gcf("PachaCuyToken");
  // PachaCuyToken = await gcf("ERC777Mock");
  // pachaCuyToken = await PachaCuyToken.deploy(
  //   vesting.address, // _vesting
  //   owner.address, // _publicSale
  //   owner.address, // _gameRewards
  //   owner.address, // _proofOfHold
  //   owner.address, // _pachacuyEvolution
  //   [owner.address]
  // );
  // await pachaCuyToken.deployed();
  // console.log("PachaCuyToken:", pachaCuyToken.address);
  pachaCuyToken = { address: "0x6112aDA65b4A4e7Bf36Dfc2Eec05C116bd51F065" };

  /**
   * PUBLIC SALE
   * 1. setPachaCuyAddress
   * 2. setVestingSCAddress
   * 3. setUsdcTokenAddress
   * 4. setExchangeRateUsdcToPcuy
   */
  PublicSalePcuy = await gcf("PublicSalePcuy");
  publicSalePcuy = await dp(PublicSalePcuy, [], {
    kind: "uups",
  });

  await publicSalePcuy.deployed();
  console.log("PublicSalePcuy Proxy:", publicSalePcuy.address);
  var publicSalePcuyImp = await getImplementation(publicSalePcuy);
  console.log("PublicSalePcuy Imp:", publicSalePcuyImp);
  /**
   * USDC
   */
  // USDC = await gcf("USDC");
  // usdc = await dp(USDC, [], {
  //   kind: "uups",
  // });
  // await usdc.deployed();
  // console.log("USDC Proxy:", usdc.address);
  // var usdcImp = await getImplementation(usdc);
  // console.log("USDC Imp:", usdcImp);
  usdc = { address: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174" };

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Finish Setting up Smart Contracts");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");

  // VESTING
  // var r = [
  //   "HOLDER_CUY_TOKEN",
  //   "PRIVATE_SALE_1",
  //   "PRIVATE_SALE_2",
  //   "AIRDROP",
  //   "PACHACUY_TEAM",
  //   "PARTNER_ADVISOR",
  //   "MARKETING",
  // ];
  // var hldrTkns = pe(String(1 * 1000000));
  // var mktTkns = pe(String(5 * 1000000));
  // var c = [
  //   hldrTkns, // * HOLDER_CUY_TOKEN     -> 1
  //   pe(String(1.5 * 1000000)), // * PRIVATE_SALE_1       -> 1.5
  //   pe(String(0.6 * 1000000)), // * PRIVATE_SALE_2       -> 0.6
  //   pe(String(1.4 * 1000000)), // * AIRDROP              -> 1.4
  //   pe(String(10 * 1000000)), // * PACHACUY_TEAM        -> 10
  //   pe(String(5 * 1000000)), // * PARTNER_ADVISOR      -> 5
  //   mktTkns, // * MARKETING            -> 5
  // ];
  var ves = vesting;
  // var pcuyA = pachaCuyToken.address;
  var pss = publicSalePcuy.address;
  var rl = manager_vesting;
  // await executeSet(ves, "settingVestingStateStructs", [r, c], "ves 001");
  // await executeSet(ves, "setPachaCuyAddress", [pcuyA], "ves 002");
  await executeSet(ves, "grantRole", [rl, pss], "ves 003");

  // PUBLIC SALE
  // ps 001 - setPachaCuyAddress
  // ps 002 - setVestingSCAddress
  // ps 003 - setUsdcTokenAddress
  // ps 004 - setExchangeRateUsdcToPcuy
  // ps 005 - setWalletForFunds
  var ps = publicSalePcuy;
  var pcuyA = pachaCuyToken.address;
  var va = vesting.address;
  var ua = usdc.address;
  var wf = process.env.WALLET_PACHACUY_FUNDS; // gnosis safe
  await executeSet(ps, "setPachaCuyAddress", [pcuyA], "ps 001");
  await executeSet(ps, "setVestingSCAddress", [va], "ps 002");
  await executeSet(ps, "setUsdcTokenAddress", [ua], "ps 003");
  await executeSet(ps, "setExchangeRateUsdcToPcuy", [25], "ps 004");
  await executeSet(ps, "setWalletForFunds", [wf], "ps 005");

  // TESTING
  var testing = false;
  if (testing) {
    var luw = "0x2Fe3b1d9f4eF17CC5BA9d82a3A94AcfE70E20DC2";
    var lew = "0xE007f0be183711DE89f6Fee70DfBB0DcBB9fC9CE";
    var usdcAmount = BigNumber.from(String(10000 * 1000000));
    await usdc.mint(luw, usdcAmount);
    await usdc.mint(lew, usdcAmount);

    // gnosis wallet
    await pachaCuyToken.transfer(
      "0xd125cCF08CA0Fe8c136a89D952BF26b69cfc8911",
      pe("4000000")
    );
  }

  if (!process.env.HARDHAT_NETWORK) return;
  // await verify(pachaCuyToken.address, "Pachacuy token", [
  //   vesting.address,
  //   owner.address,
  //   owner.address,
  //   owner.address,
  //   owner.address,
  //   [owner.address],
  // ]);
  // await verify(usdcImp, "USDC");
  // await verify(vestingImp, "Vesting");
  await verify(publicSalePcuyImp, "Public Sale");

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Verification of smart contracts finished");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
