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
  var pacAddress = "0x1509A051E5B91aAa3dE22Ae22D119C8f1Cd3DA80";
  var randomNumberGenerator = "0xBC7527D79C02Bcc2F62133900abF0C4d1D1EC9EA";
  // upgrades.silenceWarnings();

  var { _busdToken, _pcuyAddress, _walletPrivateSale } = infoHelper(NETWORK);
  // Purhcase Asset Controller
  var PurchaseAssetController = await gcf("PurchaseAssetController");
  var purchaseAssetController = await PurchaseAssetController.attach(
    pacAddress
  );

  var Tatacuy = await gcf("Tatacuy");
  var tatacuy = await dp(Tatacuy, [randomNumberGenerator], {
    kind: "uups",
  });

  await tatacuy.deployed();
  console.log("Tatacuy Proxy:", tatacuy.address);
  var tatacuyImp = await getImplementation(tatacuy);
  console.log("Tatacuy Imp:", tatacuyImp);

  // Set up
  console.log("Set up finished");

  // Verify smart contracts
  return;
  try {
    await hre.run("verify:verify", {
      address: tatacuyImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - VRF2", e);
  }
}

async function upgrade() {}

// upgrade()
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
