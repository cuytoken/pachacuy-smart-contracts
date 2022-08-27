const { expect } = require("chai");
const { formatEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const {
  safeAwait,
  infoHelper,
  updater_role,
  upgrader_role,
  pauser_role,
  uri_setter_role,
  minter_role,
  rng_generator,
  money_transfer,
  game_manager,
  manager_vesting,
  pachacuyInfoForGame,
  executeSet,
  businessesPrice,
  businessesKey,
  b,
  getDataFromEvent,
  toBytes32,
} = require("../js-utils/helpers");
const { init } = require("../js-utils/helpterTesting");
var pe = ethers.utils.parseEther;
var testing;
var cw;
var nftData;

describe("Tesing Pachacuy Game", function () {
  var owner,
    alice,
    bob,
    carl,
    deysi,
    earl,
    fephe,
    gary,
    huidobro,
    custodianWallet;
  var Vesting,
    vesting,
    PachaCuyToken,
    pachaCuyToken,
    PublicSalePcuy,
    publicSalePcuy,
    Usdc,
    usdc;
  var gcf = hre.ethers.getContractFactory;
  var dp = upgrades.deployProxy;
  var signers;
  var pe = ethers.utils.parseEther;
  var fe = ethers.utils.formatEther;

  before(async function () {
    signers = await ethers.getSigners();
    [
      owner,
      alice,
      bob,
      carl,
      deysi,
      earl,
      fephe,
      gary,
      huidobro,
      custodianWallet,
    ] = signers;
  });

  describe("Set Up", async function () {
    it("Initializes all Smart Contracts", async () => {
      /**
       * VESTING
       * 1. Gives manager_vesting to public sale sc
       */
      Vesting = await gcf("Vesting");
      vesting = await dp(Vesting, [], {
        kind: "uups",
      });
      await vesting.deployed();

      /**
       * Pachacuy Token PCUY
       * 1. Gather all operators and pass it to the initialize
       */

      // PachaCuyToken = await gcf("PachaCuyToken");
      PachaCuyToken = await gcf("ERC777Mock");
      pachaCuyToken = await PachaCuyToken.deploy(
        vesting.address, // _vesting
        owner.address, // _publicSale
        owner.address, // _gameRewards
        owner.address, // _proofOfHold
        owner.address, // _pachacuyEvolution
        [owner.address]
      );
      await pachaCuyToken.deployed();

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

      /**
       * USDC
       */
      USDC = await gcf("USDC");
      usdc = await dp(USDC, [], {
        kind: "uups",
      });
      await usdc.deployed();
    });

    it("Sets up all Smart Contracts", async () => {
      // VESTING
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
      var ves = vesting;
      var pcuyA = pachaCuyToken.address;
      var pss = publicSalePcuy.address;
      var rl = manager_vesting;
      await executeSet(ves, "settingVestingStateStructs", [r, c], "ves 001");
      await executeSet(ves, "setPachaCuyAddress", [pcuyA], "ves 002");
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
      var wf = process.env.LENIN_ADMIN_FUNDS;
      await executeSet(ps, "setPachaCuyAddress", [pcuyA], "ps 001");
      await executeSet(ps, "setVestingSCAddress", [va], "ps 002");
      await executeSet(ps, "setUsdcTokenAddress", [ua], "ps 003");
      await executeSet(ps, "setExchangeRateUsdcToPcuy", [25], "ps 004");
      await executeSet(ps, "setWalletForFunds", [wf], "ps 005");
    });
  });

  describe("Purchase", function () {
    var usdcAmount = pe("1000");
    it("No USDC allowance", async () => {
      await expect(
        publicSalePcuy.connect(alice).purchasePcuyWithUsdc(usdcAmount)
      ).to.be.revertedWith("Public Sale: Not enough USDC allowance");
      await usdc.connect(alice).approve(publicSalePcuy.address, usdcAmount);
    });

    it("No USDC funds", async () => {
      await expect(
        publicSalePcuy.connect(alice).purchasePcuyWithUsdc(usdcAmount)
      ).to.be.revertedWith("Public Sale: Not enough USDC balance");
      await usdc.mint(alice.address, usdcAmount);
    });

    it("Not enough PUCY in SC", async () => {
      await expect(
        publicSalePcuy.connect(alice).purchasePcuyWithUsdc(usdcAmount)
      ).to.be.revertedWith("Public Sale: Not enough PCUY to sell");
      var pcuyAmount = pe(String(4 * 1000000));
      //   console.log(publicSalePcuy.address, pcuyAmount);
      await pachaCuyToken.transfer(bob.address, pcuyAmount);
      await pachaCuyToken
        .connect(bob)
        .transfer(publicSalePcuy.address, pcuyAmount);
    });

    it("Alice sends USDC and gets PCUY", async () => {
      var prevAliceBal = await usdc.balanceOf(alice.address);
      var prevAliceBalPcuy = await pachaCuyToken.balanceOf(alice.address);
      await publicSalePcuy.connect(alice).purchasePcuyWithUsdc(usdcAmount);
      var afterAliceBal = await usdc.balanceOf(alice.address);
      var afterAliceBalPcuy = await pachaCuyToken.balanceOf(alice.address);
      expect(prevAliceBal.sub(afterAliceBal)).to.eq(usdcAmount);
      expect(afterAliceBalPcuy.sub(prevAliceBalPcuy)).to.eq(usdcAmount.mul(25));
    });

    it("Alice has vesting", async () => {
      var vestArr = await vesting.getArrayVestingSchema(alice.address);
      expect(vestArr.length).to.eq(1);
      var [
        fundsToVestForThisAccount,
        currentVestingPeriod,
        totalFundsVested,
        datesForVesting,
        roleOfAccount,
        uuid,
        vestingPeriods,
        tokensPerPeriod,
      ] = vestArr[0];
      expect(fundsToVestForThisAccount).to.eq(
        usdcAmount.mul(25).mul(15).div(100)
      );
    });

    it("Biz wallet receives usdc", async () => {
      var wf = process.env.LENIN_ADMIN_FUNDS;
      var val = await usdc.balanceOf(wf);
      expect(val).to.eq(usdcAmount);
    });
  });
});
