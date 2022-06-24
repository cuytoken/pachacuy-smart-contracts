require("dotenv").config();
const hre = require("hardhat");
const { ethers, providers, BigNumber } = require("ethers");

var cw = process.env.WALLET_FOR_FUNDS;
var fe = ethers.utils.formatEther;
var i = ethers.utils.Interface;
var pe = ethers.utils.parseEther;

const { expect } = require("chai");

/**
 * GPP = GUINEA_PIG_PURCHASE
 * PP = PACHA PURCHASE
 */
function mapTopic(eventName) {
  var listEvents = ["GPP", "PP", "CHKR", "MSWS", "PCHPSS"];
  if (!listEvents.includes(eventName)) throw new Error("Not an event Name");

  var tUuid = new i(["event Uuid(uint256 uuid)"]).getEventTopic("Uuid");

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
    PCHPSS: {
      topic: tUuid,
      params: ["uint256"],
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
  if (data == undefined) throw new Error("Data not found for event");
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

function init(pac, tkn, pInfo) {
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
      var tx = await pac.connect(signer).purchaseGuineaPigWithPcuy(ix);

      // check correct uuid
      var res = (await getDataFromEvent(tx, "PP")).toString();
      expect(res).to.equal(`${gpUuid}`, `Incorrect guinea pig Uuid ${gpUuid}`);

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
      args = [signer.address, res, pachaPrice.toString(), location, cw];
      expect(tx)
        .to.emit(pac, "PurchaseLand")
        .withArgs(...args);
    },
  };
}

module.exports = {
  init,
};
