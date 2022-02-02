require("dotenv").config();

const hre = require("hardhat");
const { upgrades, ethers } = require("hardhat");
const { getImplementation, infoHelper } = require("../js-utils/helpers");
// var NET = "RINKEBYTESTNET"; // BSCTESTNET
var NET = "BSCTESTNET";
const _3M = ethers.BigNumber.from("3000000000000000000000000");

async function main() {
  const [owner] = await ethers.getSigners();

  // Random Number Generator
  var { vrfCoordinator, linkToken, keyHash, fee } = infoHelper(NET);
  const RandomGen = await ethers.getContractFactory("RandomGenerator");
  const randomGenerator = await RandomGen.deploy(vrfCoordinator, linkToken);
  await randomGenerator.deployed();
  // await randomGenerator.setFee(fee);
  // await randomGenerator.setKeyHash(keyHash);
  console.log("Random Number Generator:", randomGenerator.address);

  // PachaCuyBSC
  const PachaCuyBSC = await hre.ethers.getContractFactory("PachaCuyBSC");
  const pachaCuyBSC = await upgrades.deployProxy(PachaCuyBSC, []);
  await pachaCuyBSC.deployed();
  var implementationAddressPCBSC = await getImplementation(pachaCuyBSC.address);
  console.log("PachaCuyBSC Proxy:", pachaCuyBSC.address);
  console.log("PachaCuyBSC Implementation:", implementationAddressPCBSC);

  // Airdrop
  const Airdrop = await hre.ethers.getContractFactory("Airdrop");
  const airdrop = await upgrades.deployProxy(Airdrop, []);
  await airdrop.deployed();
  var implementationAddressAD = await getImplementation(airdrop.address);
  console.log("Airdrop Proxy:", airdrop.address);
  console.log("Airdrop Implementation:", implementationAddressAD);

  // Final setting
  var { admin, capForAirdrop } = infoHelper(NET);
  try {
    await randomGenerator.setContractToReceiveRandomNG(airdrop.address);
    await pachaCuyBSC.mint(airdrop.address, _3M);
    await airdrop.setPachaCuyAddress(pachaCuyBSC.address);
    await airdrop.setRngAddress(randomGenerator.address);
    await airdrop.setCapForRandomAirdrop(capForAirdrop);
  } catch (error) {
    console.log("Error final setting:", error);
  }

  // verify contracts
  try {
    await hre.run("verify:verify", {
      address: randomGenerator.address,
      constructorArguments: [vrfCoordinator, linkToken],
    });
  } catch (error) {
    console.error("Error veryfing - RNG", error);
  }

  try {
    await hre.run("verify:verify", {
      address: implementationAddressPCBSC,
      constructorArguments: [],
    });
  } catch (error) {
    console.error("Error veryfing - PCBSC", error);
  }

  try {
    await hre.run("verify:verify", {
      address: implementationAddressAD,
      constructorArguments: [],
    });
  } catch (error) {
    console.error("Error veryfing - Airdrop", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// Pacha Cuy
// var airdropAddress = "0xfEFD786Fb9497bF88dca8dAD7D982DAa98d1a4AA";
// var pachaCuyBSCAddress = "0x0E9163C1b959011E5C394FD261b75949bb0C4d98";
// var randomGenAddress = "0x09aC231234B151B12DddEcF853F13c967F2D7779";

// const _3M = ethers.BigNumber.from("3000000000000000000000000");
// var PachaCuyBSC = await ethers.getContractFactory("PachaCuyBSC");
// var pachaCuyBSC = await PachaCuyBSC.attach(pachaCuyBSCAddress);
// await pachaCuyBSC.mint(airdropAddress, "27B46536C66C8E3000000");

// var RandomGen = await ethers.getContractFactory("RandomGenerator");
// var randomGen = await RandomGen.attach(randomGenAddress);

// var Airdrop = await ethers.getContractFactory("Airdrop");
// var airdrop = await Airdrop.attach(airdropAddress);
// await airdrop.setRngAddress(airdropAddress);

// function isHexString(value, length) {
//   if (typeof(value) !== "string" || !value.match(/^0x[0-9A-Fa-f]*$/)) {
//       return false
//   }
//   if (length && value.length !== 2 + 2 * length) { return false; }
//   return true;
// }
