const { upgrades, ethers } = require("hardhat");
const hre = require("hardhat");

const { getImplementation, infoHelper } = require("../js-utils/helpers");

// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var id = ethers.BigNumber.from(420);

async function main() {
  var [owner] = await ethers.getSigners();
  // RandomNumberGenerator Proxy: 0x31487Fe0Af1Ea67E1B6034C75E7e3B66f5B2eac8
  // RandomNumberGenerator Imp: 0xFea2B18cf5187c944b4f3B592aE859883Ec8166B
  const RandomGenerator = await gcf("RandomNumberGenerator");
  const randomGenerator = await dp(RandomGenerator, [], {
    kind: "uups",
  });
  await randomGenerator.deployed();
  console.log("RandomGenerator Proxy:", randomGenerator.address);
  var randomGeneratorImp = await getImplementation(randomGenerator);
  console.log("RandomGenerator Imp:", randomGeneratorImp);

  // final setting
  // var MKAddress = "0x10662584F69F4424f63C9A807e8ad788b587C18C";
  // await randomGenerator.addToWhiteList(MKAddress);
  // const Marketplace = await gcf("Marketplace");
  // var marketplace = await Marketplace.attach(MKAddress);
  // await marketplace.setRandomNumberGeneratorAddress(randomGenerator.address);

  // Verify smart contracts
  try {
    await hre.run("verify:verify", {
      address: randomGeneratorImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - VRF2", e);
  }
}

async function upgrade() {
  // upgrading
  var RNGAddress = "0x31487Fe0Af1Ea67E1B6034C75E7e3B66f5B2eac8";

  // const RandomGenerator = await gcf("RandomNumberGenerator");
  // var randomGenerator = await RandomGenerator.attach(RNGAddress);
  // await randomGenerator.addToWhiteList(MKAddress);

  // upgrade
  const RandomGenerator = await gcf("RandomNumberGenerator");
  await upgrades.upgradeProxy(RNGAddress, RandomGenerator);
}

// main()
upgrade()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
