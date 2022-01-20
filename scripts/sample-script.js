require("dotenv").config();

const hre = require("hardhat");
const { upgrades, ethers } = require("hardhat");
const { getImplementation } = require("../js-utils/helpers");

async function main() {
  const PachaCuy = await hre.ethers.getContractFactory("PachaCuy");
  const pachaCuy = await upgrades.deployProxy(PachaCuy, []);
  await pachaCuy.deployed();
  var implementationAddress = await getImplementation(pachaCuy.address);
  console.log("PachaCuy Token Proxy:", pachaCuy.address);
  console.log("PachaCuy Token Implementation:", implementationAddress);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
