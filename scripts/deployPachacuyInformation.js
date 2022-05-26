var { upgrades, ethers } = require("hardhat");
const hre = require("hardhat");

const {
  safeAwait,
  getImplementation,
  pachacuyInfo,
  businessesPrice,
  businessesKey,
} = require("../js-utils/helpers");

// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var id = ethers.BigNumber.from(420);

async function main() {
  var [owner] = await ethers.getSigners();

  var PachacuyInfo = await gcf("PachacuyInfo");
  var pachacuyInformation = await dp(
    PachacuyInfo,
    [pachacuyInfo.maxSamiPoints, pachacuyInfo.boxes, pachacuyInfo.affectation],
    {
      kind: "uups",
    }
  );

  await pachacuyInformation.deployed();
  console.log("PachacuyInfo Proxy:", pachacuyInformation.address);
  var pachacuyInformationImp = await getImplementation(pachacuyInformation);
  console.log("PachacuyInfo Imp:", pachacuyInformationImp);

  if (!process.env.HARDHAT_NETWORK) return;
  try {
    await hre.run("verify:verify", {
      address: pachacuyInformationImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Pachacuy Info", e);
  }
}

async function upgrade() {
  var PachacuyInformationAddress = "0xcF2dbF4C6C3574c5Aa189dd1630cfBcCfCbd3821";
  const PachacuyInfo = await gcf("PachacuyInfo");
  // await upgrades.upgradeProxy(PachacuyInformationAddress, PachacuyInfo);

  var pachacuyInfo = await PachacuyInfo.attach(PachacuyInformationAddress);
  await pachacuyInfo.setBusinessesPrice(businessesPrice, businessesKey);
}

// main()
upgrade()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
