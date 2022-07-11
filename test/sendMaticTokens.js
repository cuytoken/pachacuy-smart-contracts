const { expect } = require("chai");
const { utils, BigNumber } = require("ethers");
const { ethers } = require("hardhat");
var { Contract } = require("ethers");
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
  var PachaCuyToken, pachaCuyToken;
  var provider;

  before(async function () {
    provider = new ethers.providers.JsonRpcProvider("HTTP://127.0.0.1:7545");
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
      PachaCuyToken = await gcf("PachaCuyToken");
      pachaCuyToken = await dp(
        PachaCuyToken,
        [
          owner.address,
          owner.address,
          owner.address,
          owner.address,
          owner.address,
          [owner.address],
        ],
        {
          kind: "uups",
        }
      );
      await pachaCuyToken.deployed();
    });

    it("Send Matic to Smart Contract", async () => {
      var tx = await owner.sendTransaction({
        to: pachaCuyToken.address,
        value: ethers.utils.parseEther("5"), // Sends exactly 1.0 ether
      });
      await tx.wait();

      var balance = await provider.getBalance(pachaCuyToken.address);
      expect(utils.formatEther(balance)).to.equal("5.0");
    });

    it("Send Matic", async () => {
      var address = new ethers.Wallet.createRandom().address;
      var amount = BigNumber.from("10000");
      var tx = await pachaCuyToken.sendMaticAndTokens(address, amount);
      var balancePcuy = await pachaCuyToken.balanceOf(address);
      var balanceAfterMatic = await provider.getBalance(address);

      expect(balancePcuy.toString()).equal(amount.toString());
      expect(utils.formatEther(balanceAfterMatic)).equal("0.2");
    });

    it("Send Matic 2", async () => {
      var address = new ethers.Wallet.createRandom().address;
      var value = ethers.utils.parseEther("0.1");

      var tx = await owner.sendTransaction({
        to: address,
        value,
      });

      var amount = BigNumber.from("10000");
      await pachaCuyToken.sendMaticAndTokens(address, amount);
      var balancePcuy = await pachaCuyToken.balanceOf(address);
      var balanceAfterMatic = await provider.getBalance(address);

      expect(balancePcuy.toString()).equal(amount.toString());
      expect(utils.formatEther(balanceAfterMatic)).equal("0.2");
    });
  });
});
