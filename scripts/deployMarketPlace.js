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
   * RandomNumberGenerator Proxy: 0xF8DeC4a35Cf32f59D0E338458EA996EFF90Be483
    RandomNumberGenerator Imp: 0xD1349732f128e21e9a8bD974a0fF1fA9b7d62a11
    PurchaseAC Proxy: 0x1e7749812C53d150D179b3468f5963ABa98244a5
    PurchaseAC Imp: 0x95F99e19f620b9597AeA5C0D461D4e905fC67b72
    NftProducerPachacuy Proxy: 0xE70937A750B9155eea884b089918155Fd256752A
    NftProducerPachacuy Imp: 0x346D115931De44615CE365D3f5ed9DA3C792999F
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
    PurchaseAC Proxy: 0x2d902d04CeC54997b83919b6F80Bf5f9fcF9eAB6
PurchaseAC Imp: 0x3645fb3c5516C63B7715e12341BA50921D1ea7E2
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
   NftProducerPachacuy Proxy: 0x32368894EFca7fa3e3170Feb0EdA80F24c7b8983
NftProducerPachacuy Imp: 0x15Fc24E01b9D64c6003395705772799AaCF09076
   * 1. Grant Mint roles to PurchaseAssetController
   */
  const NftProducerPachacuy = await gcf("NftProducerPachacuy");
  const nftProducerPachacuy = await dp(NftProducerPachacuy, [], {
    kind: "uups",
  });
  await nftProducerPachacuy.deployed();
  console.log("NftProducerPachacuy Proxy:", nftProducerPachacuy.address);
  var nftProducerPachacuyImp = await getImplementation(nftProducerPachacuy);
  console.log("NftProducerPachacuy Imp:", nftProducerPachacuyImp);

  // final setting
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
}

async function upgrade() {
  // upgrading
  // var RNGAddress = "0x4c8545746F51B5a99AfFE5cd7c79364506fA1d7b";
  // const RandomNumberGenerator = await gcf("RandomNumberGenerator");
  // await upgrades.upgradeProxy(RNGAddress, RandomNumberGenerator);

  var PACAddress = "0x1e7749812C53d150D179b3468f5963ABa98244a5";
  const PurchaseAssetController = await gcf("PurchaseAssetController");
  await upgrades.upgradeProxy(PACAddress, PurchaseAssetController);

  var NFTPAddress = "0xE70937A750B9155eea884b089918155Fd256752A";
  const NftProducerPachacuy = await gcf("NftProducerPachacuy");
  await upgrades.upgradeProxy(NFTPAddress, NftProducerPachacuy);
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
