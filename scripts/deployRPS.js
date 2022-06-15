var { upgrades, ethers } = require("hardhat");
const hre = require("hardhat");

const { safeAwait, verify, getImplementation } = require("../js-utils/helpers");

var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;

async function main() {
  var RPS = await gcf("RockPaperScissors");
  var rps = await dp(RPS, [], { kind: "uups" });

  await rps.deployed();
  console.log("RPS Proxy:", rps.address);
  var rpsImp = await getImplementation(rps);
  console.log("RPS Imp:", rpsImp);

  // Verify smart contracts
  if (!process.env.HARDHAT_NETWORK) return;
  await verify(rpsImp, "RPS");
}

async function upgrade() {
  var RockPaperScissorsAddress = "0x2F308566ca703d5Edbc2AA602410Aa8a358d4dE8";
  const RockPaperScissors = await gcf("RockPaperScissors");
  await upgrades.upgradeProxy(RockPaperScissorsAddress, RockPaperScissors);
}

main()
  // upgrade()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
