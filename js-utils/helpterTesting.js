require("dotenv").config();
const hre = require("hardhat");
const { ethers, providers, BigNumber } = require("ethers");

var cw = process.env.WALLET_FOR_FUNDS;
var fe = ethers.utils.formatEther;
var i = ethers.utils.Interface;
var pe = ethers.utils.parseEther;
var bn = (num) => ethers.BigNumber.from(String(num));
var secsInADay = 60 * 60 * 24;

const { expect } = require("chai");
const { toBytes32 } = require("./helpers");

/**
 * GPP = GUINEA_PIG_PURCHASE
 * PP = PACHA PURCHASE
 */
function mapTopic(eventName) {
  var listEvents = [
    "GPP",
    "PP",
    "CHKR",
    "MSWS",
    "PCHPSS",
    "RFFLSTRT",
    "QTWS",
    "TCKTRFFL",
    "PCPS",
    "HTWS",
    "WRCCH",
  ];
  if (!listEvents.includes(eventName)) throw new Error("Not an event Name");

  // topic uuid
  var tUuid = new i(["event Uuid(uint256 uuid)"]).getEventTopic("Uuid");
  // topic start raffle contest
  var tStrtRffl = new i([
    "event RaffleStarted(uint256 misayWasiUuid, uint256 rafflePrize, uint256 ticketPrice, uint256 campaignStartDate, uint256 campaignEndDate, uint256 pachaUuid)",
  ]).getEventTopic("RaffleStarted");
  // topic ticket raffle uuid
  var tTcktRfflUuid = new i([
    "event UuidAndAmount(uint256 uuid, uint256 amount)",
  ]).getEventTopic("UuidAndAmount");
  // guinea pig finish
  var tGNPFNSH = new i([
    "event GuineaPigPurchaseFinish(address _account, uint256 price, uint256 _guineaPigId, uint256 _uuid, string _raceAndGender, uint256 balanceConsumer)",
  ]).getEventTopic("GuineaPigPurchaseFinish");

  var map = {
    GPP: {
      topic: tUuid,
      params: ["uint256"],
    },
    PP: {
      topic: tUuid,
      params: ["uint256"],
    },
    CHKR: {
      topic: tUuid,
      params: ["uint256"],
    },
    MSWS: {
      topic: tUuid,
      params: ["uint256"],
    },
    WRCCH: {
      topic: tUuid,
      params: ["uint256"],
    },
    PCHPSS: {
      topic: tUuid,
      params: ["uint256"],
    },
    QTWS: {
      topic: tUuid,
      params: ["uint256"],
    },
    PCPS: {
      topic: tUuid,
      params: ["uint256"],
    },
    HTWS: {
      topic: tUuid,
      params: ["uint256"],
    },
    TCKTRFFL: {
      topic: tTcktRfflUuid,
      params: ["uint256", "uint256"],
    },
    RFFLSTRT: {
      topic: tStrtRffl,
      params: [
        "uint256",
        "uint256",
        "uint256",
        "uint256",
        "uint256",
        "uint256",
      ],
    },
  };

  return map[eventName];
}

async function getDataFromEvent(tx, eventName) {
  var { topic, params } = mapTopic(eventName);

  var res = await tx.wait();
  var data;
  for (var ev of res.events) {
    if (ev.topics.includes(topic)) {
      data = ev.data;
      break;
    }
  }
  if (data == undefined) console.error(`Data not found for event ${eventName}`);
  return ethers.utils.defaultAbiCoder.decode(params, data);
}

var businessesPrice = [
  10, //  0 - CHAKRA
  200, // 1 - PACHA
  3, //   2 - QHATU_WASI
  10, //  3 - MISAY_WASI
  5, //   4 - GUINEA_PIG_1
  10, //  5 - GUINEA_PIG_2
  15, //  6 - GUINEA_PIG_3
];
var businesses = [
  "CHAKRA",
  "PACHA",
  "QHATU_WASI",
  "MISAY_WASI",
  "GUINEA_PIG_1",
  "GUINEA_PIG_2",
  "GUINEA_PIG_3",
];

function _getRadomNumberOne(_random, _account) {}

function init(pac, tkn, pInfo, chakra, pInfo, guineaP, msws, rNumb, nftP) {
  return {
    purchaseGuineaPig: async function (signer, args) {
      var [gpUuid, ix] = args;
      var GUINEAPIG = `GUINEA_PIG_${ix}`;
      var guineaPigPrice = pe(String(businessesPrice[3 + ix]));
      guineaPigPrice = await pInfo.convertBusdToPcuy(guineaPigPrice);

      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);

      // purchase
      await pac.connect(signer).purchaseGuineaPigWithPcuy(ix);
      var tx = await rNumb.fulfillRandomWords(324324, [1232, 123244333]);

      // check correct uuid
      var res = (await getDataFromEvent(tx, "GPP")).toString();
      expect(res).to.equal(`${gpUuid}`, `Wrong guinea pig Uuid ${gpUuid}`);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);

      // check balances signer
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        guineaPigPrice.toString(),
        "Incorrect price account"
      );

      // check if custodian wallet received funds
      expect(afterBalCustodianW.sub(prevBalCustodianW).toString()).to.equal(
        guineaPigPrice.toString(),
        "Incorrect price custodian"
      );

      // event
      //   args = [signer.address, res, guineaPigPrice.toString(), location, cw];
      expect(tx).to.emit(pac, "GuineaPigPurchaseFinish");
      // .withArgs(...args);
    },
    purchaseLand: async function (signer, args) {
      var [location, pachaUuid] = args;
      var PACHA = "PACHA";
      var pachaPrice = pe(String(businessesPrice[1]));
      pachaPrice = await pInfo.convertBusdToPcuy(pachaPrice);

      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);

      // purchase
      var tx = await pac.connect(signer).purchaseLandWithPcuy(location);

      // check correct uuid
      var res = (await getDataFromEvent(tx, "PP")).toString();
      expect(res).to.equal(`${pachaUuid}`, `Incorrect Pacha Uuid ${pachaUuid}`);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);

      // check balances signer
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        pachaPrice.toString(),
        "Incorrect price account"
      );

      // check if custodian wallet received funds
      expect(afterBalCustodianW.sub(prevBalCustodianW).toString()).to.equal(
        pachaPrice.toString(),
        "Incorrect price custodian"
      );

      // event
      args = [
        signer.address,
        res,
        pachaPrice.toString(),
        location,
        cw,
        afterBalAcc,
      ];
      expect(tx)
        .to.emit(pac, "PurchaseLand")
        .withArgs(...args);
    },
    purchaseChakra: async function (signer, args) {
      var [pachaUuid, chakraUuid] = args;
      var CHAKRA = "CHAKRA";
      var chakraPrice = pe(String(businessesPrice[0]));
      chakraPrice = await pInfo.convertBusdToPcuy(chakraPrice);

      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);

      // purchase
      var tx = await pac.connect(signer).purchaseChakra(pachaUuid);

      // check correct uuid
      var res = (await getDataFromEvent(tx, "CHKR")).toString();
      expect(res).to.equal(
        `${chakraUuid}`,
        `Incorrect Pacha Uuid ${chakraUuid}`
      );

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);

      // check balances signer
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        chakraPrice.toString(),
        "Incorrect price account"
      );

      // check if custodian wallet received funds
      expect(afterBalCustodianW.sub(prevBalCustodianW).toString()).to.equal(
        chakraPrice.toString(),
        "Incorrect price custodian"
      );
    },
    purchaseFood: async function (signer, args) {
      var [chakraUuid, amountFood, guineaPiguuid] = args;

      // prev guineaPig
      var {
        feedingDate: feedingDatePrev,
        burningDate: burningDatePrev,
        daysUntilHungry,
      } = await guineaP.getGuineaPigWithUuid(guineaPiguuid);

      var {
        owner: ownerChakra,
        pricePerFood,
        availableFood: availableFoodPrev,
      } = await chakra.getChakraWithUuid(chakraUuid);

      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);
      var prevBalOwnerChakra = await tkn.balanceOf(ownerChakra);

      var totalToSpent = pricePerFood.mul(bn(amountFood));

      var tax = await pInfo.purchaseTax();
      var fee = totalToSpent.mul(tax).div(100);
      var net = totalToSpent.sub(fee);

      var tx1 = await pac
        .connect(signer)
        .purchaseFoodFromChakra(chakraUuid, amountFood, guineaPiguuid);

      var { availableFood: availableFoodAfter } =
        await chakra.getChakraWithUuid(chakraUuid);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);
      var afterBalOwnerChakra = await tkn.balanceOf(ownerChakra);

      // check if custodian wallet received funds
      expect(afterBalCustodianW.sub(prevBalCustodianW).toString()).to.equal(
        fee.toString(),
        "Incorrect price custodian"
      );
      // check balances signer
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        totalToSpent.toString(),
        "Incorrect price account"
      );
      // check balance chakra owner
      expect(afterBalOwnerChakra.sub(prevBalOwnerChakra).toString()).to.equal(
        net.toString(),
        "Incorrect price custodian"
      );

      // check food amount decreases
      expect(availableFoodPrev.sub(availableFoodAfter).toNumber()).to.equal(
        amountFood,
        `${chakraUuid} error amount of food`
      );

      // after guineaPig
      var { feedingDate: feedingDateAfter, burningDate: burningDateAfter } =
        await guineaP.getGuineaPigWithUuid(guineaPiguuid);

      expect(feedingDateAfter.sub(feedingDatePrev).toString()).to.equal(
        String(secsInADay * amountFood * daysUntilHungry)
      );
      expect(burningDateAfter.sub(burningDatePrev).toString()).to.equal(
        String(secsInADay * amountFood * daysUntilHungry)
      );
    },
    purchaseMisaywasi: async function (signer, args) {
      var [mswsUuid, pachaUuid] = args;
      var MISAY_WASI = "MISAY_WASI";
      var mswsPrice = pe(String(businessesPrice[3]));
      mswsPrice = await pInfo.convertBusdToPcuy(mswsPrice);

      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);

      // purchase
      var tx = await pac.connect(signer).purchaseMisayWasi(pachaUuid);

      // check correct uuid
      var res = (await getDataFromEvent(tx, "MSWS")).toString();
      expect(res).to.equal(`${mswsUuid}`, `Incorrect MSWS Uuid ${mswsUuid}`);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);

      // check balances signer
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        mswsPrice.toString(),
        "Incorrect price account"
      );

      // check if custodian wallet received funds
      expect(afterBalCustodianW.sub(prevBalCustodianW).toString()).to.equal(
        mswsPrice.toString(),
        "Incorrect price custodian"
      );
    },
    startMisayWasiRaffle: async function (signer, args) {
      var [mswsUuid, prize, tPrice, endDate, startDate, pachaUuid] = args;

      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);

      var tx = await msws
        .connect(signer)
        .startMisayWasiRaffle(mswsUuid, prize, tPrice, endDate);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);

      // check balances signer
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        prize.toString(),
        "Incorrect price account"
      );

      // check if custodian wallet received funds
      expect(afterBalCustodianW.sub(prevBalCustodianW).toString()).to.equal(
        prize.toString(),
        "Incorrect price custodian"
      );

      var args = [mswsUuid, prize, tPrice, startDate + 1, endDate, pachaUuid];
      await expect(tx)
        .to.emit(msws, "RaffleStarted")
        .withArgs(...args);
    },
    purchaseTicket: async function (signer, args) {
      var [owner, mswsUuid, tPrice, amountTickets, tcktUuid] = args;
      var cost = tPrice.mul(bn(amountTickets));

      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalOwner = await tkn.balanceOf(owner.address);

      var tx = await pac
        .connect(signer)
        .purchaseTicketFromMisayWasi(mswsUuid, amountTickets);

      // check correct uuid
      var [_tcktUuid, _tckts] = await getDataFromEvent(tx, "TCKTRFFL");
      expect(_tcktUuid.toString()).to.equal(
        `${tcktUuid}`,
        `Incorrect Uuid ${tcktUuid}`
      );

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalOwner = await tkn.balanceOf(owner.address);

      // check balances signer
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        cost.toString(),
        "Incorrect price account"
      );

      expect(afterBalOwner.sub(prevBalOwner).toString()).to.equal(
        cost.toString(),
        "Owner incorrect received"
      );
    },
    purchaseQhatuWasi: async function (signer, args) {
      var [pachaUuid, qtwsUuid] = args;
      var qtwsPrice = pe(String(businessesPrice[2]));
      qtwsPrice = await pInfo.convertBusdToPcuy(qtwsPrice);

      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);

      var tx = await pac.connect(signer).purchaseQhatuWasi(pachaUuid);

      // check correct uuid
      var res = (await getDataFromEvent(tx, "QTWS")).toString();
      expect(res).to.equal(`${qtwsUuid}`, `Incorrect Uuid ${qtwsUuid}`);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);

      // check balances signer
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        qtwsPrice.toString(),
        "Incorrect price account"
      );

      // check if custodian wallet received funds
      expect(afterBalCustodianW.sub(prevBalCustodianW).toString()).to.equal(
        qtwsPrice.toString(),
        "Incorrect price custodian"
      );
    },
    purchasePachaPass: async function (signer, args) {
      var [pachaUuid, pcpsUuid, pricePass, ownerPacha] = args;
      var tax = await pInfo.purchaseTax();
      var fee = pricePass.mul(tax).div(100);
      var net = pricePass.sub(fee);

      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);
      var prevBalOwnerPacha = await tkn.balanceOf(ownerPacha);

      var tx = await pac.connect(signer).purchasePachaPass(pachaUuid);
      // check correct uuid
      var res = (await getDataFromEvent(tx, "PCPS")).toString();
      expect(res).to.equal(`${pcpsUuid}`, `Incorrect Uuid ${pcpsUuid}`);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);
      var afterBalOwnerPacha = await tkn.balanceOf(ownerPacha);

      // check if custodian wallet received funds
      expect(afterBalCustodianW.sub(prevBalCustodianW).toString()).to.equal(
        fee.toString(),
        "Incorrect price custodian"
      );
      // check balances signer
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        pricePass.toString(),
        "Incorrect price account"
      );
      // check balance chakra owner
      expect(afterBalOwnerPacha.sub(prevBalOwnerPacha).toString()).to.equal(
        net.toString(),
        "Incorrect price owner"
      );
    },
    mintHatunWasi: async function (signer, args) {
      var [pachaUuid, hwUuid] = args;
      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);

      /**
        function mint(
          bytes32 _nftType,
          bytes memory _data,
          address _account
        )
       */
      var _nftType = toBytes32("HATUNWASI");
      var _data = ethers.utils.defaultAbiCoder.encode(
        ["address", "uint256", "uint256"],
        [signer.address, pachaUuid, 0]
      );
      var tx = await nftP.connect(signer).mint(_nftType, _data, signer.address);
      // check correct uuid
      var res = (await getDataFromEvent(tx, "HTWS")).toString();
      expect(res).to.equal(`${hwUuid}`, `Incorrect Uuid ${hwUuid}`);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);

      // check balances signer
      expect(prevBalAcc).to.equal(afterBalAcc, "Incorrect price account");
      // check balance chakra owner
      expect(afterBalCustodianW).to.equal(prevBalCustodianW, "Incorrect CW");
    },
    mintTatacuy: async function (signer, args) {
      var [pachaUuid, ttcyUuid] = args;
      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);

      /**
        function mint(
          bytes32 _nftType,
          bytes memory _data,
          address _account
        )
       */
      var _nftType = toBytes32("TATACUY");
      var _data = ethers.utils.defaultAbiCoder.encode(
        ["address", "uint256", "uint256"],
        [signer.address, pachaUuid, 0]
      );
      var tx = await nftP.connect(signer).mint(_nftType, _data, signer.address);
      // check correct uuid
      var res = (await getDataFromEvent(tx, "HTWS")).toString();
      expect(res).to.equal(`${ttcyUuid}`, `Incorrect Uuid ${ttcyUuid}`);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);

      // check balances signer
      expect(prevBalAcc).to.equal(afterBalAcc, "Incorrect price account");
      // check balance chakra owner
      expect(afterBalCustodianW).to.equal(prevBalCustodianW, "Incorrect CW");
    },
    mintWiracocha: async function (signer, args) {
      var [pachaUuid, wrcchUuid] = args;
      // prev balance
      var prevBalAcc = await tkn.balanceOf(signer.address);
      var prevBalCustodianW = await tkn.balanceOf(cw);

      /**
        function mint(
          bytes32 _nftType,
          bytes memory _data,
          address _account
        )
       */
      var _nftType = toBytes32("WIRACOCHA");
      var _data = ethers.utils.defaultAbiCoder.encode(
        ["address", "uint256", "uint256"],
        [signer.address, pachaUuid, 0]
      );
      var tx = await nftP.connect(signer).mint(_nftType, _data, signer.address);
      // check correct uuid
      var res = (await getDataFromEvent(tx, "WRCCH")).toString();
      expect(res).to.equal(`${wrcchUuid}`, `Incorrect Uuid ${wrcchUuid}`);

      // after balance
      var afterBalAcc = await tkn.balanceOf(signer.address);
      var afterBalCustodianW = await tkn.balanceOf(cw);

      // check balances signer
      expect(prevBalAcc).to.equal(afterBalAcc, "Incorrect price account");
      // check balance chakra owner
      expect(afterBalCustodianW).to.equal(prevBalCustodianW, "Incorrect CW");
    },
  };
}

module.exports = {
  init,
};
