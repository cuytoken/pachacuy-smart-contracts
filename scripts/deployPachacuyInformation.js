var { upgrades, ethers } = require("hardhat");
const hre = require("hardhat");

const {
  safeAwait,
  getImplementation,
  pachacuyInfo,
} = require("../js-utils/helpers");

// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var id = ethers.BigNumber.from(420);

async function main() {
  var [owner] = await ethers.getSigners();

  var PachacuyInformation = await gcf("PachacuyInformation");
  var pachacuyInformation = await dp(
    PachacuyInformation,
    [pachacuyInfo.maxSamiPoints, pachacuyInfo.boxes, pachacuyInfo.affectation],
    {
      kind: "uups",
    }
  );

  await pachacuyInformation.deployed();
  console.log("PachacuyInformation Proxy:", pachacuyInformation.address);
  var pachacuyInformationImp = await getImplementation(pachacuyInformation);
  console.log("PachacuyInformation Imp:", pachacuyInformationImp);

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
  var PachacuyInformationAddress = "0xB9ca45D3d4288745636d8a904a42E92741C5aBB8";
  const PachacuyInformation = await gcf("PachacuyInformation");
  await upgrades.upgradeProxy(PachacuyInformationAddress, PachacuyInformation);
}

// upgrade();
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
