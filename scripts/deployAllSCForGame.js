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
  money_transfer,
  game_manager,
} = require("../js-utils/helpers");

// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;

async function main() {
  var [owner] = await ethers.getSigners();
  if (!process.env.HARDHAT_NETWORK) upgrades.silenceWarnings();

  /**
   * RANDOM NUMBER GENERATOR
   * 1.  Set Random Number Generator address as consumer in VRF subscription
   * 2. 001 Add PurchaseAssetController sc within the whitelist of Random Number Generator
   * 2. 002 Add Tatacuy sc within the whitelist of Random Number Generator
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
   * 2. 003 setNftProducerPachacuyAddress
   * 3. 004 set Pcuy token address
   * 4. 005 grant role rng_generator to the random number generator sc
   * 5. 006 grant role money_transfer to Tatacuy
   *    006.1 grant role money_transfer to Wiracocha
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
   * 1. 007 Grant Mint roles to PurchaseAssetController
   *    007.1 set Tatacuy Address
   *    007.2 set Wiracocha Address
   *
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
   * Tatacuy
   * 1, 008 Tatacuy must grant game_manager role to relayer bsc testnet
   * 2, 009 Tatacuy must grant game_manager role to Nft producer
   * 3. 010 Grant role rng_generator to the random number generator sc
   * 4. 011 set address of purchase asset controller in Tatacuy
   *
   */
  var relayerBSCTestnetAddress = process.env.RELAYER_ADDRESS_BSC_TESTNET;
  var Tatacuy = await gcf("Tatacuy");
  var tatacuy = await dp(Tatacuy, [randomNumberGenerator.address], {
    kind: "uups",
  });
  await tatacuy.deployed();
  console.log("Tatacuy Proxy:", tatacuy.address);
  var tatacuyImp = await getImplementation(tatacuy);
  console.log("Tatacuy Imp:", tatacuyImp);

  /**
   * Wiracocha
   * 1. 011.1 Gave game_manager to relayer
   * 2. 011.2 Gave game_manager to Nft Producer
   * 2. 011.3 set address of purchase asset controller in Wiracocha
   */
  var relayerBSCTestnetAddress = process.env.RELAYER_ADDRESS_BSC_TESTNET;
  var Wiracocha = await gcf("Wiracocha");
  var wiracocha = await dp(Wiracocha, [], {
    kind: "uups",
  });
  await wiracocha.deployed();
  console.log("Wiracocha Proxy:", wiracocha.address);
  var wiracochaImp = await getImplementation(wiracocha);
  console.log("Wiracocha Imp:", wiracochaImp);

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
  var pachacuyTokenImp = await getImplementation(pachaCuyToken);
  console.log("PachaCuyToken Imp:", pachacuyTokenImp);

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Finish Setting up Smart Contracts");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");

  // FINAL SETTING
  await safeAwait(
    () => randomNumberGenerator.addToWhiteList(purchaseAssetController.address),
    "Random Number 001"
  );
  await safeAwait(
    () => randomNumberGenerator.addToWhiteList(tatacuy.address),
    "Random Number 002"
  );

  // Purhcase Asset Controller
  await safeAwait(
    () =>
      purchaseAssetController.setNftProducerPachacuyAddress(
        nftProducerPachacuy.address
      ),
    "Setting NftProducerPachacuy Address 003"
  );
  await safeAwait(
    () => purchaseAssetController.setPcuyTokenAddress(pachaCuyToken.address),
    "PachaCuyToken address 004"
  );
  await safeAwait(
    () =>
      purchaseAssetController.grantRole(
        rng_generator,
        randomNumberGenerator.address
      ),
    "Granting RNG role 005"
  );
  await safeAwait(
    () => purchaseAssetController.grantRole(money_transfer, tatacuy.address),
    "Granting RNG role 006"
  );
  await safeAwait(
    () => purchaseAssetController.grantRole(money_transfer, wiracocha.address),
    "Granting RNG role 006.1"
  );

  // Nft Producer
  await safeAwait(
    () =>
      nftProducerPachacuy.grantRole(
        minter_role,
        purchaseAssetController.address
      ),
    "Granting Mint role 007"
  );
  await safeAwait(
    () => nftProducerPachacuy.setTatacuyAddress(tatacuy.address),
    "Granting Mint role 007.1"
  );
  await safeAwait(
    () => nftProducerPachacuy.setWiracochaAddress(wiracocha.address),
    "Granting Mint role 007.2"
  );

  // Tatacuy
  await safeAwait(
    () => tatacuy.grantRole(game_manager, relayerBSCTestnetAddress),
    "Granting Mint role 008"
  );
  await safeAwait(
    () => tatacuy.grantRole(game_manager, nftProducerPachacuy.address),
    "Granting Mint role 009"
  );
  await safeAwait(
    () => tatacuy.grantRole(rng_generator, randomNumberGenerator.address),
    "Granting Mint role 010"
  );
  await safeAwait(
    () =>
      tatacuy.setAddressPurchaseAssetController(
        purchaseAssetController.address
      ),
    "Add address of purchase Asset Controller 011"
  );

  // Wiracocha
  await safeAwait(
    () => wiracocha.grantRole(game_manager, relayerBSCTestnetAddress),
    "Granting Mint role 011.1"
  );
  await safeAwait(
    () => wiracocha.grantRole(game_manager, nftProducerPachacuy.address),
    "Granting Mint role 011.2"
  );
  await safeAwait(
    () =>
      wiracocha.setAddressPurchaseAssetController(
        purchaseAssetController.address
      ),
    "Granting Mint role 011.3"
  );
  console.log("Final setting finished!");

  // Verify smart contracts
  if (!process.env.HARDHAT_NETWORK) return;
  try {
    await hre.run("verify:verify", {
      address: randomGeneratorImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Random Number G.", e);
  }

  try {
    await hre.run("verify:verify", {
      address: purchaseAContImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Purhcase Asset Controller", e);
  }

  try {
    await hre.run("verify:verify", {
      address: nftProducerPachacuyImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Nft Producer", e);
  }

  try {
    await hre.run("verify:verify", {
      address: tatacuyImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Tatacuy", e);
  }

  try {
    await hre.run("verify:verify", {
      address: wiracochaImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Wiracocha", e);
  }

  try {
    await hre.run("verify:verify", {
      address: pachacuyTokenImp,
      constructorArguments: [],
    });
  } catch (e) {
    console.error("Error veryfing - Token", e);
  }

  console.log("Verification of smart contracts finished");
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
main()
  // upgrade()
  // resetOngoingTransaction()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
