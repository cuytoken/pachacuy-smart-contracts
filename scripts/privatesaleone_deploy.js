require("dotenv").config();

const hre = require("hardhat");
const { upgrades, ethers } = require("hardhat");
const { getImplementation, infoHelper } = require("../js-utils/helpers");
// var NET = "RINKEBYTESTNET"; // BSCTESTNET
// var NET = "BSCTESTNET";
var NET = "BSCNET";
const _3M = ethers.BigNumber.from("3000000000000000000000000");

async function main() {
  const [owner] = await ethers.getSigners();

  // PachaCuyBSC
  // const PachaCuyBSC = await hre.ethers.getContractFactory("PachaCuyBSC");
  // const pachaCuyBSC = await upgrades.deployProxy(PachaCuyBSC, []);
  // await pachaCuyBSC.deployed();
  // var implementationAddressPCBSC = await getImplementation(pachaCuyBSC.address);
  // console.log("PachaCuyBSC Proxy:", pachaCuyBSC.address);
  // console.log("PachaCuyBSC I:", implementationAddressPCBSC);

  // PrivateSaleOne
  var { _exchangeRatePrivateSaleOne, _busdToken, _walletPrivateSale } =
    infoHelper(NET);

  const PrivateSaleOne = await hre.ethers.getContractFactory("PrivateSaleOne");
  const privateSaleOne = await upgrades.deployProxy(PrivateSaleOne, [
    "0xe9e7cea3dedca5984780bafc599bd69add087d56",
    "0x77A45071c532b71Cb4c99126D9A98c1D86276D3A",
    _exchangeRatePrivateSaleOne,
  ]);
  await privateSaleOne.deployed();
  var implementationAddressPS = await getImplementation(privateSaleOne.address);
  console.log("PrivateSaleOne Proxy:", privateSaleOne.address);
  console.log("PrivateSaleOne I:", implementationAddressPS);

  // try {
  //   await pachaCuyBSC.mint(owner.address, _3M);
  //   await pachaCuyBSC.mint(process.env.WALLET_PACHACUY_BUSINESS, _3M);
  // } catch (error) {
  //   console.log("Error final setting:", error);
  // }

  // verify contracts
  // try {
  //   await hre.run("verify:verify", {
  //     address: implementationAddressPCBSC,
  //     constructorArguments: [],
  //   });
  // } catch (error) {
  //   console.error("Error veryfing - BUSD mock", error);
  // }

  try {
    await hre.run("verify:verify", {
      address: implementationAddressPS,
      constructorArguments: [],
    });
  } catch (error) {
    console.error("Error veryfing - Private S", error);
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
