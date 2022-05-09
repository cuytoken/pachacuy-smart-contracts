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

  /**
   * RANDOM NUMBER GENERATOR
   * 1. Set Random Number Generator address as consumer in VRF subscription
   * 2. Add PurchaseAssetController sc within the whitelist
   RandomNumberGenerator Proxy: 0x1ce83650ccb7705CEd8fDfe1d872B2021d5D3E98
RandomNumberGenerator Imp: 0x18EE2236C7B92f1141AA56d0A1052E01B93Eb65E
   */
  const RandomNumberGenerator = await gcf("RandomNumberGenerator");
  const randomNumberGenerator = await dp(RandomNumberGenerator, [], {
    kind: "uups",
  });
  await randomNumberGenerator.deployed();
  console.log("RandomNumberGenerator Proxy:", randomNumberGenerator.address);
  var randomGeneratorImp = await getImplementation(randomNumberGenerator);
  console.log("RandomNumberGenerator Imp:", randomGeneratorImp);

  /**
   * Purchase Asset Controller
   * 1. Pass within the initialize the ranmdom number generator address
   * 2. setNftProducerPachacuyAddress
   * 3. grant role rng_generator to the random number generator sc
   */
  var { _busdToken } = infoHelper(NETWORK);
  const PurchaseAssetController = await gcf("PurchaseAssetController");
  const purchaseAssetController = await dp(
    PurchaseAssetController,
    [randomNumberGenerator.address, process.env.WALLET_FOR_FUNDS, _busdToken],
    {
      kind: "uups",
    }
  );
  await purchaseAssetController.deployed();
  console.log("PurchaseAC Proxy:", purchaseAssetController.address);
  var purchaseAContImp = await getImplementation(purchaseAssetController);
  console.log("PurchaseAC Imp:", purchaseAContImp);

  /**
   * NFT Producer
   * 1. Grant Mint roles to PurchaseAssetController
   */
  var name = "In-game NFT Pachacuy";
  var symbol = "NFTGAMEPCUY";
  const NftProducerPachacuy = await gcf("NftProducerPachacuy");
  const nftProducerPachacuy = await dp(NftProducerPachacuy, [name, symbol], {
    kind: "uups",
  });
  await nftProducerPachacuy.deployed();
  console.log("NftProducerPachacuy Proxy:", nftProducerPachacuy.address);
  var nftProducerPachacuyImp = await getImplementation(nftProducerPachacuy);
  console.log("NftProducerPachacuy Imp:", nftProducerPachacuyImp);

  /**
   * Pachacuy Token PCUY
   * 1. Gather all operators and pass it to the initialize
   */
  const PachaCuyToken = await gcf("PachaCuyToken");
  const pachaCuyToken = await dp(
    PachaCuyToken,
    [
      owner.address,
      owner.address,
      owner.address,
      owner.address,
      owner.address,
      [purchaseAssetController.address],
    ],
    {
      kind: "uups",
    }
  );
  await pachaCuyToken.deployed();
  console.log("PachaCuyToken Proxy:", pachaCuyToken.address);
  var pachacuyImp = await getImplementation(pachaCuyToken);
  console.log("PachaCuyToken Imp:", pachacuyImp);

  // FINAL SETTING
  await safeAwait(
    () => purchaseAssetController.setPacuyTokenAddress(pachaCuyToken.address),
    "PachaCuyToken address"
  );

  await safeAwait(
    () => randomNumberGenerator.addToWhiteList(purchaseAssetController.address),
    "Random Number"
  );
  await safeAwait(
    () =>
      nftProducerPachacuy.grantRole(
        minter_role,
        purchaseAssetController.address
      ),
    "Granting Mint role"
  );
  await safeAwait(
    () =>
      purchaseAssetController.setNftProducerPachacuyAddress(
        nftProducerPachacuy.address
      ),
    "Setting NftProducerPachacuy Address"
  );
  await safeAwait(
    () =>
      purchaseAssetController.grantRole(
        rng_generator,
        randomNumberGenerator.address
      ),
    "Granting RNG role"
  );
  console.log("Final setting finished!");

  // Verify smart contracts
  try {
    await hre.run("verify:verify", {
      address: randomGeneratorImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - VRF2", e);
  }

  try {
    await hre.run("verify:verify", {
      address: purchaseAContImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Market place", e);
  }

  try {
    await hre.run("verify:verify", {
      address: nftProducerPachacuyImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Guinea Pig", e);
  }

  try {
    await hre.run("verify:verify", {
      address: pachacuyImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Guinea Pig", e);
  }
}

async function upgrade() {
  // upgrading
  // var RNGAddress = "0x4c8545746F51B5a99AfFE5cd7c79364506fA1d7b";
  // const RandomNumberGenerator = await gcf("RandomNumberGenerator");
  // await upgrades.upgradeProxy(RNGAddress, RandomNumberGenerator);

  var PACAddress = "0x1509A051E5B91aAa3dE22Ae22D119C8f1Cd3DA80";
  const PurchaseAssetController = await gcf("PurchaseAssetController");
  await upgrades.upgradeProxy(PACAddress, PurchaseAssetController);

  // var NFTPAddress = "0x1517184267098FE72EAfE06971606Bb311966175";
  // const NftProducerPachacuy = await gcf("NftProducerPachacuy");
  // await upgrades.upgradeProxy(NFTPAddress, NftProducerPachacuy);
}

async function resetOngoingTransaction() {
  var [owner] = await ethers.getSigners();

  var RNGAddress = "0x4c8545746F51B5a99AfFE5cd7c79364506fA1d7b";
  const RandomNumberGenerator = await gcf("RandomNumberGenerator");
  const randomNumberGenerator = await RandomNumberGenerator.attach(RNGAddress);

  var PACAddress = "0xBeb87CD6b6C5132834cCd692799e9Caba80b80F1";
  const PurchaseAssetController = await gcf("PurchaseAssetController");
  const purchaseAssetController = await PurchaseAssetController.attach(
    PACAddress
  );

  await randomNumberGenerator.resetOngoinTransaction(owner.address);
  await purchaseAssetController.resetOngoingTransactionForAccount(
    owner.address
  );
  await purchaseAssetController.purchaseGuineaPigWithBusd(1);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// main()
upgrade()
  // resetOngoingTransaction()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
