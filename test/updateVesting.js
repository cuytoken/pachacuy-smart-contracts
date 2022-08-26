const { expect } = require("chai");
const { formatEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const {
  safeAwait,
  getImplementation,
  toBytes32,
  executeSet,
  callSequenceAgnostic,
} = require("../js-utils/helpers");
const { init } = require("../js-utils/helpterTesting");
const NETWORK = "BSCTESTNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var pe = ethers.utils.parseEther;

function formatDate(arrayDates) {
  var options = {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  };
  return arrayDates.map((date) => {
    var today = new Date(date.toNumber() * 1000);
    return today.toLocaleDateString(options);
  });
}

describe("Tesing Pachacuy Game", function () {
  async function getTimeStamp(show = false) {
    var blockNumBefore = await ethers.provider.getBlockNumber();
    var blockBefore = await ethers.provider.getBlock(blockNumBefore);
    if (show) console.log(blockBefore.timestamp);
    return blockBefore.timestamp;
  }

  async function advanceAMonth(month, ts = 1661990400, dx = 0) {
    var secsM = 2592000;
    await network.provider.send("evm_setNextBlockTimestamp", [
      ts + secsM * month + dx,
    ]);
    await network.provider.send("evm_mine");
  }

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

  describe("Set Up PCUY y Vesting SCs", async function () {
    it("Initializes all Smart Contracts", async () => {
      var [owner] = await ethers.getSigners();
      if (process.env.HARDHAT_NETWORK) upgrades.silenceWarnings();

      Vesting = await gcf("Vesting");
      vesting = await dp(Vesting, [], {
        kind: "uups",
      });
      await vesting.deployed();

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
      var r = [
        "HOLDER_CUY_TOKEN",
        "PRIVATE_SALE_1",
        "PRIVATE_SALE_2",
        "AIRDROP",
        "PACHACUY_TEAM",
        "PARTNER_ADVISOR",
        "MARKETING",
      ];

      // Vesting
      var ves = vesting;
      var pcuyA = pachaCuyToken.address;
      await executeSet(ves, "settingVestingStateStructs", [r, c], "ves 001");
      await executeSet(ves, "setPachaCuyAddress", [pcuyA], "ves 002");
    });
  });

  describe("Vesting SC", async function () {
    it("Recibes balance", async () => {
      var balance = await pachaCuyToken.balanceOf(vesting.address);
      expect(balance).to.equal(c.reduce((prev, curr) => prev.add(curr)));
    });
  });

  describe("Vesting", async function () {
    it("Register for a non-existant role", async () => {
      var ts = 1661990400;
      await expect(
        vesting.createVestingSchema(
          alice.address,
          pe("1"),
          4,
          ts,
          "NON_EXISTANT_ROLE"
        )
      ).to.be.revertedWith("Vesting: Not a valid role.");
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
    });

    it("Register holders", async () => {
      // reading data from csv file
      var file = "vestingData/airdrop1.csv";
      var data = require("fs").readFileSync(file, "utf8");
      data = data.split("\r\n");
      var _accounts = [];
      var _fundsToVestArray = [];
      var _vestingPeriods = [];
      var _releaseDays = [];
      var _roleOfAccounts = [];
      var date = "1658188800"; // Date and time (GMT): Tuesday, 19 July 2022 0:00:00
      data.forEach((row) => {
        var line = row.split(",");
        _accounts.push(line[0]);
        _fundsToVestArray.push(pe(line[1]));
        _vestingPeriods.push(Number(line[2]));
        _releaseDays.push(date);
        _roleOfAccounts.push(line[3]);
      });
      var vt = vesting;
      var cm = "createVestingSchemaBatch";

      var inc = 40;
      var methods = [];

      for (var ix = 0; ix < Math.ceil(_accounts.length / inc); ix++) {
        function includePush(_ix) {
          if (_ix == 4 || _ix == 3 || _ix == 2 || _ix == 1) {
            console.log("before push _ix", _ix);
            methods.push(() => {
              var beg = _ix * inc;
              var end = Math.min((_ix + 1) * inc, _accounts.length);
              var _a = _accounts.slice(beg, end);
              console.log("_ix", _ix);
              console.log("l", _a.length);
              console.log("beg", beg);
              console.log("end", end);
              var _f = _fundsToVestArray.slice(beg, end);
              var _v = _vestingPeriods.slice(beg, end);
              var _d = _releaseDays.slice(beg, end);
              var _r = _roleOfAccounts.slice(beg, end);
              return vt[cm](_a, _f, _v, _d, _r);
            });
          }
        }
        includePush(ix);
      }

      await callSequenceAgnostic(methods);
    });

    it("Vesting received", async () => {
      var add = "0xA9962974e1152C34b67CDE52fD473a59E07c8e36";
      var res = await vesting.getArrayVestingSchema(add);
      expect(res.length).to.be.equal(1);
      var add = "0x96cefee552b0e0ab1ae79da5e8efd728b1a45f56";
      var res = await vesting.getArrayVestingSchema(add);
      expect(res.length).to.be.equal(1);
      var add = "0x22ce697867db42897bb73212268aab4955dcabdb";
      var res = await vesting.getArrayVestingSchema(add);
      expect(res.length).to.be.equal(1);
      var add = "0xb440e263dc41313fb4e0128433b3315544a8efb9";
      var res = await vesting.getArrayVestingSchema(add);
      expect(res.length).to.be.equal(1);
    });
  });
});
