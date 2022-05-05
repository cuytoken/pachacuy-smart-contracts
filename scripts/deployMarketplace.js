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
  var pachacuyCollectionAddress = "0x9af90A0fFFbe809DC4e738fB2713FF3E53B045e6";
  var nftProducerAddress = "0x1517184267098FE72EAfE06971606Bb311966175";
  // upgrades.silenceWarnings();

  var { _busdToken, _pcuyAddress, _walletPrivateSale } = infoHelper(NETWORK);
  var MarketplacePachacuy = await gcf("MarketplacePachacuy");
  var marketplacePachacuy = await dp(
    MarketplacePachacuy,
    [_walletPrivateSale, _busdToken],
    {
      kind: "uups",
    }
  );

  await marketplacePachacuy.deployed();
  console.log("MarketplacePachacuy Proxy:", marketplacePachacuy.address);
  var mktplcImp = await getImplementation(marketplacePachacuy);
  console.log("MarketplacePachacuy Imp:", mktplcImp);

  // Set up
  await marketplacePachacuy.setErc721Address(pachacuyCollectionAddress);
  await marketplacePachacuy.setErc1155Address(nftProducerAddress);

  // PCUY token not supported yet
  // await marketplacePachacuy.setPachacuyTokenAddress(_pcuyAddress);
  console.log("Set up finished");

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

async function upgrade() {
  var MktplcAddress = "0x6a354eC3975e748fc863A77DFb0409e68384AA73";
  const MarketplacePachacuy = await gcf("MarketplacePachacuy");
  await upgrades.upgradeProxy(MktplcAddress, MarketplacePachacuy);
}

// main()
upgrade()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
