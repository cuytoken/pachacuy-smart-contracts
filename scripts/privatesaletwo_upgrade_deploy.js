require("dotenv").config();

const hre = require("hardhat");
const { upgrades, ethers } = require("hardhat");
const { getImplementation, infoHelper } = require("../js-utils/helpers");
// var NET = "RINKEBYTESTNET"; // BSCTESTNET
var NET = "BSCTESTNET";
// var NET = "BSCNET";
const _3M = ethers.BigNumber.from("3000000000000000000000000");

async function main() {
  const [owner] = await ethers.getSigners();

  // PrivateSaleTwo Proxy: 0x4e1d9E925DF794df0393f38869Ef9df493b6074a
  // PrivateSaleTwo I: 0xfDe8ADB396EBc0560E4cB1f58f10E5eC3cE93D44
  const PrivateSaleTwo = await ethers.getContractFactory("PrivateSaleTwoV2");
  const privateSaleTwo = await upgrades.upgradeProxy(
    "0x4e1d9E925DF794df0393f38869Ef9df493b6074a",
    PrivateSaleTwo
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
