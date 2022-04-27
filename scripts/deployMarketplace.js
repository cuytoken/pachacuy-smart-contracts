var { upgrades, ethers } = require("hardhat");
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
  // upgrades.silenceWarnings();

  var { _busdToken, _pcuyAddress, _walletPrivateSale } = infoHelper(NETWORK);
  var MarketplacePachacuy = await gcf("MarketplacePachacuy");
  var marketplacePachacuy = await dp(
    MarketplacePachacuy,
    [_walletPrivateSale, _busdToken, _pcuyAddress],
    {
      kind: "uups",
    }
  );
  await marketplacePachacuy.deployed();
  console.log("MarketplacePachacuy Proxy:", marketplacePachacuy.address);
  var mktplcImp = await getImplementation(marketplacePachacuy);
  console.log("MarketplacePachacuy Imp:", mktplcImp);

  // Verify smart contracts
  try {
    await hre.run("verify:verify", {
      address: mktplcImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - VRF2", e);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
