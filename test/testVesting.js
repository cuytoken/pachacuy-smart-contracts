const { expect } = require("chai");
const { formatEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const {
  safeAwait,
  getImplementation,
  toBytes32,
  executeSet,
} = require("../js-utils/helpers");
const { init } = require("../js-utils/helpterTesting");
const NETWORK = "BSCTESTNET";
var cw = process.env.WALLET_FOR_FUNDS;
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;

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
  var pe = ethers.utils.parseEther;
  var PachaCuyToken, pachaCuyToken, pachacuyTokenImp;
  var Vesting, vesting;

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
    async function getTimeStamp() {
      var blockNumBefore = await ethers.provider.getBlockNumber();
      var blockBefore = await ethers.provider.getBlock(blockNumBefore);
      console.log(blockBefore.timestamp);
      return blockBefore.timestamp;
    }

    it("Initializes all Smart Contracts", async () => {
      var [owner] = await ethers.getSigners();
      if (process.env.HARDHAT_NETWORK) upgrades.silenceWarnings();

      Vesting = await gcf("Vesting");
      vesting = await dp(Vesting, [], {
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
      console.log("PachaCuyToken Proxy:", pachaCuyToken.address);

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

      var c = [
        pe("1"),
        pe("1.5"),
        pe("0.6"),
        pe("1.2"),
        pe("12"),
        pe("10"),
        pe("10"),
      ];
      // Vesting
      var ves = vesting;
      var pcuyA = pachaCuyToken.address;
      await executeSet(ves, "settingVestingStateStructs", [r, c], "ves 001");
      await executeSet(ves, "setPachaCuyAddress", [pcuyA], "ves 002");
    });

    it("Register vesting", async () => {
      /**
       * ROLES FOR VESTING       Q
       * -----
       * HOLDER_CUY_TOKEN     -> 1
       * PRIVATE_SALE_1       -> 1.5
       * PRIVATE_SALE_2       -> 0.6
       * AIRDROP              -> 1.2
       * PACHACUY_TEAM        -> 12
       * PARTNER_ADVISOR      -> 10
       * MARKETING            -> 10
       * ------------------------------------
       * TOTAL                -> 36.3
       */

      // timestamp 1661990400: Thursday, 1 September 2022 0:00:00
      var ts = 1661990400;
      var secMonth = 2592000;
      await network.provider.send("evm_setNextBlockTimestamp", [ts]);
      await network.provider.send("evm_mine");
      // await network.provider.send("evm_increaseTime", [3600]);

      await getTimeStamp();

      var _accounts = [alice, bob, carl, deysi, earl, fephe].map(
        (signer) => signer.address
      );
      var _fundsToVestArray = [
        pe("1"),
        pe("1"),
        pe("1"),
        pe("1"),
        pe("1"),
        pe("1"),
      ];
      var _vestingPeriods = [12, 12, 12, 12, 12, 12];
      var _releaseDays = [
        1661990400, 1661990400, 1661990400, 1661990400, 1661990400, 1661990400,
      ];
      var _roleOfAccounts = [
        "MARKETING",
        "MARKETING",
        "MARKETING",
        "MARKETING",
        "MARKETING",
        "MARKETING",
      ];

      await vesting.createVestingSchemaBatch(
        _accounts,
        _fundsToVestArray,
        _vestingPeriods,
        _releaseDays,
        _roleOfAccounts
      );

      await network.provider.send("evm_increaseTime", [secMonth]);
      await network.provider.send("evm_mine");
      await getTimeStamp();

      var res = await vesting.getArrayVestingSchema(alice.address);
      console.log(res);

      await vesting.connect(alice).claimTokensWithVesting(0);
      var res = await vesting.getArrayVestingSchema(alice.address);
      console.log(res);
    });
  });
});
