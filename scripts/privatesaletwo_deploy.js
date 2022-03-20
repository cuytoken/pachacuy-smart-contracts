require("dotenv").config();

const hre = require("hardhat");
const { upgrades, ethers } = require("hardhat");
const { getImplementation, infoHelper } = require("../js-utils/helpers");
// var NET = "RINKEBYTESTNET"; // BSCTESTNET
// var NET = "BSCTESTNET";
var NET = "BSCNET";

async function main() {
  const [owner] = await ethers.getSigners();

  // PrivateSaleTwo
  var { _exchangeRatePrivateSaleTwo, _busdToken, _walletPrivateSale } =
    infoHelper(NET);

  const PrivateSaleTwo = await hre.ethers.getContractFactory("PrivateSaleTwo");
  const privateSaleTwo = await upgrades.deployProxy(PrivateSaleTwo, [
    _busdToken,
    _walletPrivateSale,
    _exchangeRatePrivateSaleTwo,
  ]);
  await privateSaleTwo.deployed();
  var implementationAddressPS = await getImplementation(privateSaleTwo.address);
  console.log("PrivateSaleTwo Proxy:", privateSaleTwo.address);
  console.log("PrivateSaleTwo I:", implementationAddressPS);

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
