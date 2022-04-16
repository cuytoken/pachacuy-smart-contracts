const { upgrades, ethers } = require("hardhat");
const hre = require("hardhat");

const {
  safeAwait,
  getImplementation,
  infoHelper,
  updater_role,
  upgrader_role,
  pauser_role,
  uri_setter_role,
  minter_role,
  rng_generator,
} = require("../js-utils/helpers");

// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var id = ethers.BigNumber.from(420);

async function main() {
  var [owner] = await ethers.getSigners();
  upgrades.silenceWarnings();
  const PachacuyToken = await gcf("PachacuyToken");
  const pachacuyToken = await dp(PachacuyToken, [[owner.address]], {
    kind: "uups",
  });
  await pachacuyToken.deployed();
  console.log("PachacuyToken Proxy:", pachacuyToken.address);
  var pachacuyImp = await getImplementation(pachacuyToken);
  console.log("PachacuyToken Imp:", pachacuyImp);

  try {
    await hre.run("verify:verify", {
      address: pachacuyImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Guinea Pig", e);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
