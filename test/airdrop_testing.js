const { expect } = require("chai");
const { ethers } = require("hardhat");
const { getImplementation, infoHelper } = require("../js-utils/helpers");

describe("Airdrop", function () {
  var RandomGen,
    randomGenerator,
    PachaCuyBSC,
    pachaCuyBSC,
    Airdrop,
    airdrop,
    RNGMock,
    rNGMock;
  var owner, alice;
  var _3M = ethers.BigNumber.from("3000000000000000000000000");
  var NET = "RINKEBYTESTNET"; // BSCTESTNET

  before(async function () {
    [owner, alice] = await ethers.getSigners();
  });

  describe("Airdrop", function () {
    it("Setting up smart contracts", async function () {
      var { vrfCoordinator, linkToken, keyHash, fee } = infoHelper(NET);
      RandomGen = await ethers.getContractFactory("RandomGenerator");
      randomGenerator = await RandomGen.deploy(vrfCoordinator, linkToken);
      await randomGenerator.deployed();
      await randomGenerator.setFee(fee);
      await randomGenerator.setKeyHash(keyHash);
      console.log("Random Number Generator:", randomGenerator.address);

      // RNG Mock
      RNGMock = await ethers.getContractFactory("RNGMock");
      rNGMock = await RNGMock.deploy();
      await rNGMock.deployed();
      console.log("Random Number Generator:", rNGMock.address);

      // PachaCuyBSC
      PachaCuyBSC = await hre.ethers.getContractFactory("PachaCuyBSC");
      pachaCuyBSC = await upgrades.deployProxy(PachaCuyBSC, []);
      await pachaCuyBSC.deployed();
      var implementationAddress = await getImplementation(pachaCuyBSC.address);
      console.log("PachaCuyBSC Proxy:", pachaCuyBSC.address);
      console.log("PachaCuyBSC Implementation:", implementationAddress);

      // Airdrop
      Airdrop = await hre.ethers.getContractFactory("Airdrop");
      airdrop = await upgrades.deployProxy(Airdrop, []);
      await airdrop.deployed();
      var implementationAddress = await getImplementation(airdrop.address);
      console.log("Airdrop Proxy:", airdrop.address);
      console.log("Airdrop Implementation:", implementationAddress);

      // Final setting
      var { admin, capForAirdrop } = infoHelper(NET);
      await pachaCuyBSC.mint(airdrop.address, _3M);
      await airdrop.setPachaCuyAddress(pachaCuyBSC.address);
      await airdrop.setRngAddress(rNGMock.address);
      await airdrop.setCapForRandomAirdrop(capForAirdrop);
      await rNGMock.setContractToReceiveRandomNG(airdrop.address);
    });

    it("Participating in Airdrop", async function () {
      var balanceAirdrop = await pachaCuyBSC.balanceOf(airdrop.address);
      expect(balanceAirdrop.toString()).equal(_3M);

      await airdrop.participateRandomAirdrop500(alice.address);
    });
  });
});
