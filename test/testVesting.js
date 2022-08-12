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

    it("Register vesting HOLDER_CUY_TOKEN", async () => {
      // timestamp 1661990400: Thursday, 1 September 2022 0:00:00
      var ts = 1661990400;
      var _accounts = [alice, bob, carl, deysi, earl];
      var _addresses = _accounts.map((signer) => signer.address);
      var _fundsToVestArray = [
        hldrTkns.div(_accounts.length), // uuid 0
        hldrTkns.div(_accounts.length), // uuid 1
        hldrTkns.div(_accounts.length), // uuid 2
        hldrTkns.div(_accounts.length), // uuid 3
        hldrTkns.div(_accounts.length), // uuid 4
      ];
      var _vestingPeriods = [10, 10, 10, 10, 10];
      var _releaseDays = [ts, ts, ts, ts, ts];
      var _roleOfAccounts = Array(5)
        .fill(null)
        .map(() => "HOLDER_CUY_TOKEN");

      await vesting.createVestingSchemaBatch(
        _addresses,
        _fundsToVestArray,
        _vestingPeriods,
        _releaseDays,
        _roleOfAccounts
      );

      _addresses.map(async (address) => {
        var res = await vesting.getArrayVestingSchema(address);
        expect(res.length).to.equal(1);
      });

      function transform(vestingPerAccount) {
        return {
          fundsToVestForThisAccount: formatEther(vestingPerAccount[0]),
          currentVestingPeriod: vestingPerAccount[1].toNumber(),
          totalFundsVested: formatEther(vestingPerAccount[2]),
          datesForVesting: formatDate(vestingPerAccount[3]),
          roleOfAccount: vestingPerAccount[4],
          uuid: vestingPerAccount[5].toString(),
          vestingPeriods: vestingPerAccount[6].toNumber(),
          tokensPerPeriod: formatEther(vestingPerAccount[7]),
        };
      }

      var arrayOfVesting = await vesting.getArrayVestingSchema(alice.address);
      var res2 = arrayOfVesting.map(transform);
      console.log(res2);
    });

    it("Alice starts with zero tokens", async () => {
      var balance = await pachaCuyToken.balanceOf(alice.address);
      expect(balance.toString()).to.equal(String(0));
    });

    it("Claiming HOLDER_CUY_TOKEN wrong time", async () => {
      await expect(
        vesting.connect(alice).claimTokensWithUuid(0)
      ).to.be.revertedWith(
        "Vesting: You already claimed tokens for the current vesting period"
      );
    });

    it("Claiming HOLDER_CUY_TOKEN", async () => {
      // advance time to month 1
      await advanceAMonth(1);

      // vesting month one
      await vesting.connect(alice).claimTokensWithUuid(0);

      var uuid = 0;
      var [
        fundsToVestForThisAccount,
        currentVestingPeriod,
        totalFundsVested,
        datesForVesting,
        roleOfAccount,
        uuid,
        vestingPeriods,
        tokensPerPeriod,
      ] = await vesting.getVestingSchemaWithUuid(alice.address, uuid);
      expect(fundsToVestForThisAccount).to.equal(hldrTkns.div(5), "Error at 1");
      expect(currentVestingPeriod.toNumber()).to.equal(1, "Error at 2");
      expect(totalFundsVested).to.equal(hldrTkns.div(5).div(10), "Error at 3");
      var ts = 1661990400;
      var secsM = 2592000;
      datesForVesting.forEach((date, ix) =>
        expect(date.toString()).to.equal(
          String(1661990400 + 2592000 * (ix + 1)),
          `Error at 4 ${ix}`
        )
      );
      expect(roleOfAccount).to.equal("HOLDER_CUY_TOKEN", "Error at 5");
      expect(uuid.toNumber()).to.equal(0, "Error at 6");
      expect(vestingPeriods.toNumber()).to.equal(10, "Error at 7");
      expect(tokensPerPeriod).to.equal(hldrTkns.div(5).div(10), "Error at 8");
    });

    it("Alice receives one month vesting", async () => {
      var balance = await pachaCuyToken.balanceOf(alice.address);
      expect(balance).to.equal(hldrTkns.div(5).div(10));
    });

    it("Vesting is completed and fails", async () => {
      // should failed if asked twice
      await expect(
        vesting.connect(alice).claimTokensWithUuid(0)
      ).to.be.revertedWith(
        "Vesting: You already claimed tokens for the current vesting period"
      );
    });

    it("Completes a vesting for alice", async () => {
      await advanceAMonth(2); // to month 2
      await vesting.connect(alice).claimTokensWithUuid(0);
      await advanceAMonth(3); // to month 3
      await vesting.connect(alice).claimTokensWithUuid(0);
      await advanceAMonth(4); // to month 4
      await vesting.connect(alice).claimTokensWithUuid(0);
      await advanceAMonth(5); // to month 5
      await vesting.connect(alice).claimTokensWithUuid(0);
      await advanceAMonth(6); // to month 6
      await vesting.connect(alice).claimTokensWithUuid(0);
      await advanceAMonth(7); // to month 7
      await vesting.connect(alice).claimTokensWithUuid(0);
      await advanceAMonth(8); // to month 8
      await vesting.connect(alice).claimTokensWithUuid(0);
      await advanceAMonth(9); // to month 9
      await vesting.connect(alice).claimTokensWithUuid(0);
      await advanceAMonth(10); // to month 10
      await vesting.connect(alice).claimTokensWithUuid(0);
    });

    it("Vesting periods completed ", async () => {
      // should failed if asked twice
      await expect(
        vesting.connect(alice).claimTokensWithUuid(0)
      ).to.be.revertedWith("Vesting: All tokens for vesting have been claimed");
    });

    it("Alice receives 10 month vesting", async () => {
      var balance = await pachaCuyToken.balanceOf(alice.address);
      expect(balance).to.equal(hldrTkns.div(5));
    });

    it("After 10 months, claim all", async () => {
      var balance = await pachaCuyToken.balanceOf(bob.address);
      expect(balance.toString()).to.equal(String(0), "Initial Bob balance");

      await vesting.connect(bob).claimTokensWithUuid(1);

      var balance = await pachaCuyToken.balanceOf(bob.address);
      expect(balance).to.equal(hldrTkns.div(5), "Final Bob balance");
    });

    it("All HOLDER_CUY_TOKEN is claimed", async () => {
      await vesting.connect(carl).claimTokensWithUuid(2);
      await vesting.connect(deysi).claimTokensWithUuid(3);
      await vesting.connect(earl).claimTokensWithUuid(4);

      var balance = await pachaCuyToken.balanceOf(vesting.address);
      expect(balance).to.equal(
        c.reduce((prev, curr) => prev.add(curr)).sub(hldrTkns),
        "Vesting balance incorrect"
      );
    });

    it("HOLDER_CUY_TOKEN reaches its limit", async () => {
      var ts = 1661990400;
      await expect(
        vesting.createVestingSchema(
          alice.address,
          pe("1"),
          10,
          ts,
          "HOLDER_CUY_TOKEN"
        )
      ).to.be.revertedWith(
        "Vesting: Not enough funds to allocate for vesting."
      );
    });
  });

  describe("Vesting 2nd group - MARKETING", () => {
    var ts;
    var _accounts;
    var _addresses;
    it("Register vesting MARKETING", async () => {
      ts = await getTimeStamp();
      _accounts = [alice, bob, carl, deysi, earl];
      _addresses = _accounts.map((signer) => signer.address);
      var _fundsToVestArray = [
        mktTkns.div(_accounts.length), // uuid 5
        mktTkns.div(_accounts.length), // uuid 6
        mktTkns.div(_accounts.length), // uuid 7
        mktTkns.div(_accounts.length), // uuid 8
        mktTkns.div(_accounts.length), // uuid 9
      ];
      var _vestingPeriods = [10, 10, 10, 10, 10];
      var _releaseDays = [ts, ts, ts, ts, ts];
      var _roleOfAccounts = Array(5)
        .fill(null)
        .map(() => "MARKETING");

      await vesting.createVestingSchemaBatch(
        _addresses,
        _fundsToVestArray,
        _vestingPeriods,
        _releaseDays,
        _roleOfAccounts
      );
    });

    it("Fails when half month passes", async () => {
      await advanceAMonth(0.5, ts);

      var promises = _accounts.map((account, ix) =>
        expect(
          vesting.connect(account).claimTokensWithUuid(5 + ix)
        ).to.be.revertedWith(
          "Vesting: You already claimed tokens for the current vesting period"
        )
      );
      await Promise.all(promises);
    });

    it("Succeds when a month passes", async () => {
      await advanceAMonth(1, ts, 5);

      await vesting.connect(alice).claimTokensWithUuid(5);
      await vesting.connect(bob).claimTokensWithUuid(6);
      await vesting.connect(carl).claimTokensWithUuid(7);
      await vesting.connect(deysi).claimTokensWithUuid(8);
      await vesting.connect(earl).claimTokensWithUuid(9);
    });

    it("Fails when 1.5 month passes", async () => {
      await advanceAMonth(1.5, ts);

      await expect(
        vesting.connect(_accounts[0]).claimTokensWithUuid(5)
      ).to.be.revertedWith(
        "Vesting: You already claimed tokens for the current vesting period"
      );
    });

    it("Succeds when two month pass", async () => {
      await advanceAMonth(2, ts);
      await vesting.connect(alice).claimTokensWithUuid(5);
      await vesting.connect(bob).claimTokensWithUuid(6);
      await vesting.connect(carl).claimTokensWithUuid(7);
      await vesting.connect(deysi).claimTokensWithUuid(8);
      await vesting.connect(earl).claimTokensWithUuid(9);
    });

    it("Removes vesting from account", async () => {
      var [role, fundsForAllocation, fundsAllocatedPrev] =
        await vesting.getStatusOfFundByRole("MARKETING");

      await vesting.removesVestingSchemaForAccount(alice.address, 5);
      var uuid = 5;
      await expect(
        vesting.getVestingSchemaWithUuid(alice.address, uuid)
      ).to.be.revertedWith("Vesting: Account is not vesting.");

      var [role, fundsForAllocation, fundsAllocatedAfter] =
        await vesting.getStatusOfFundByRole("MARKETING");

      expect(fundsAllocatedPrev.sub(fundsAllocatedAfter)).to.be.equal(
        mktTkns.div(5).div(10).mul(8)
      );
    });
  });
});
