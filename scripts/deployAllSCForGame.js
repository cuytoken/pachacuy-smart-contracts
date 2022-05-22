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
  pachacuyInfoForGame,
  verify,
  executeSet,
} = require("../js-utils/helpers");

// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;

async function main() {
  var [owner] = await ethers.getSigners();
  if (process.env.HARDHAT_NETWORK) upgrades.silenceWarnings();

  /**
   * PACHACUY INFORMATION
   * - pI 001 - set chakra address
   * - pI 002 - set pool reward address
   * - pI 003 - DEFAULT - set purchase tax
   * - pI 004 - DEFAULT - set minimum sami points per box
   * - pI 005 - DEFAULT - set maximum sami points per box
   * - pI 006 - DEFAULT - set total food per chakra
   * - pI 007 - DEFAULT set exchange rate pcuy to sami
   * - pI 008 - set hatun wasi address
   * - pI 009 - setTatacuyAddress
   * - pI 010 - setWiracochaAddress
   * - pI 011 - set Purchase A C A ddress
   * - pI 012 - setPachaCuyTokenAddress
   */
  var PachacuyInfo = await gcf("PachacuyInfo");
  var pachacuyInfo = await dp(
    PachacuyInfo,
    [
      pachacuyInfoForGame.maxSamiPoints,
      pachacuyInfoForGame.boxes,
      pachacuyInfoForGame.affectation,
    ],
    {
      kind: "uups",
    }
  );

  await pachacuyInfo.deployed();
  console.log("PachacuyInfo Proxy:", pachacuyInfo.address);
  var pachacuyInfoImp = await getImplementation(pachacuyInfo);
  console.log("PachacuyInfo Imp:", pachacuyInfoImp);

  /**
   * RANDOM NUMBER GENERATOR
   * 1. Set Random Number Generator address as consumer in VRF subscription
   * 2. rng 001 - Add PurchaseAssetController sc within the whitelist of Random Number Generator
   * 2. rng 002 - Add Tatacuy sc within the whitelist of Random Number Generator
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
   * 2. PAC 001 setNftPAddress
   * 3. PAC 002 set Pcuy token address
   * 4. PAC 003 grant role rng_generator to the random number generator sc
   * 5. PAC 004 grant role money_transfer to Tatacuy
   * 6. PAC 005 grant role money_transfer to Wiracocha
   * 7. PAC 006 set Pachacuy Info address with setPachacuyInfoAddress
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
   * nftP 001 - Grant Mint roles to PurchaseAssetController
   * nftP 002 - set setPachacuyInfoaddress
   * nftP 003 - grant game_role to PurchaseAssetController
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
   * 1, tt 001 - Tatacuy must grant game_manager role to relayer bsc testnet
   * 2, tt 002 - Tatacuy must grant game_manager role to Nft producer
   * 3. tt 003 - Grant role rng_generator to the random number generator sc
   * 4. tt 004 - setPachacuyInfoAddress
   *
   */
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
   * 1. wi 001 - Gave game_manager to relayer
   * 2. wi 002 - Gave game_manager to Nft Producer
   * 2. wi 003 - Gave game_manager to Purchase asset contoller
   * 2. wi 004 - setPachacuyInfoAddress
   */
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

  /**
   * CHAKRA
   * 1. ck 002 - Initialize - Pass the info contract address in initialize
   * 2. ck 001 - Grant game_manager role to Nft producer
   */
  var Chakra = await gcf("Chakra");
  var chakra = await dp(Chakra, [pachacuyInfo.address], {
    kind: "uups",
  });

  await chakra.deployed();
  console.log("Chakra Proxy:", chakra.address);
  var chakraImp = await getImplementation(chakra);
  console.log("Chakra Imp:", chakraImp);

  /**
   * HATUN WASI
   * 1. hw 001 - Grant game_manager role to Nft producer
   */
  var HatunWasi = await gcf("HatunWasi");
  var hatunWasi = await dp(HatunWasi, [], {
    kind: "uups",
  });

  await hatunWasi.deployed();
  console.log("Hatun Wasi Proxy:", hatunWasi.address);
  var hatunWasiImp = await getImplementation(hatunWasi);
  console.log("Hatun Wasi Imp:", hatunWasiImp);

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Finish Setting up Smart Contracts");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");

  // RANDOM NUMBER GENERATOR
  var rng = randomNumberGenerator;
  var pacAdd = purchaseAssetController.address;
  var ttAdd = tatacuy.address;
  await executeSet(rng, "addToWhiteList", [pacAdd], "rng 001");
  await executeSet(rng, "addToWhiteList", [ttAdd], "rng 002");

  // PURCHASE ASSET CONTROLLER
  var pac = purchaseAssetController;
  var nftPAdd = nftProducerPachacuy.address;
  var pCuyAdd = pachaCuyToken.address;
  var rngAdd = randomNumberGenerator.address;
  var ttAdd = tatacuy.address;
  var wAdd = wiracocha.address;
  var pIAdd = pachacuyInfo.address;
  await executeSet(pac, "setNftPAddress", [nftPAdd], "PAC 001");
  await executeSet(pac, "setPcuyTokenAddress", [pCuyAdd], "PAC 002");
  await executeSet(pac, "grantRole", [rng_generator, rngAdd], "PAC 003");
  await executeSet(pac, "grantRole", [money_transfer, ttAdd], "PAC 004");
  await executeSet(pac, "grantRole", [money_transfer, wAdd], "PAC 005");
  await executeSet(pac, "setPachacuyInfoAddress", [pIAdd], "PAC 006");

  // NFT PRODUCER
  var nftP = nftProducerPachacuy;
  var pacAdd = purchaseAssetController.address;
  var ttAdd = tatacuy.address;
  var wAd = wiracocha.address;
  var pIAdd = pachacuyInfo.address;
  await executeSet(nftP, "grantRole", [minter_role, pacAdd], "nftP 001");
  await executeSet(nftP, "setPachacuyInfoaddress", [pIAdd], "nftP 002");
  await executeSet(nftP, "grantRole", [game_manager, pacAdd], "nftP 003");

  // Tatacuy
  var tt = tatacuy;
  var rel = process.env.RELAYER_ADDRESS_BSC_TESTNET;
  var nftAdd = nftProducerPachacuy.address;
  var pacAdd = purchaseAssetController.address;
  var rngAdd = randomNumberGenerator.address;
  var pIAdd = pachacuyInfo.address;
  await executeSet(tt, "grantRole", [game_manager, rel], "tt 001");
  await executeSet(tt, "grantRole", [game_manager, nftAdd], "tt 002");
  await executeSet(tt, "grantRole", [rng_generator, rngAdd], "tt 003");
  await executeSet(tt, "setPachacuyInfoAddress", [pIAdd], "tt 004");

  // Wiracocha
  var wi = wiracocha;
  var rel = process.env.RELAYER_ADDRESS_BSC_TESTNET;
  var nftAdd = nftProducerPachacuy.address;
  var pacAdd = purchaseAssetController.address;
  var pIAdd = pachacuyInfo.address;
  await executeSet(wi, "grantRole", [game_manager, rel], "wi 001");
  await executeSet(wi, "grantRole", [game_manager, nftAdd], "wi 002");
  await executeSet(wi, "grantRole", [game_manager, pacAdd], "wi 003");
  await executeSet(wi, "setPachacuyInfoAddress", [pIAdd], "wi 004");

  // CHAKRA
  var ck = chakra;
  var nftAdd = nftProducerPachacuy.address;
  await executeSet(ck, "grantRole", [game_manager, nftAdd], "ck 001");

  // PACHACUY INFORMATION
  var pI = pachacuyInfo;
  var wallet = process.env.WALLET_FOR_FUNDS;
  var hwAdd = hatunWasi.address;
  var wir = wiracocha.address;
  var ttc = tatacuy.address;
  var pacAdd = purchaseAssetController.address;
  var pcuyAdd = pachaCuyToken.address;
  await executeSet(pI, "setChakraAddress", [chakra.address], "pI 001");
  await executeSet(pI, "setPoolRewardAddress", [wallet], "pI 002");
  await executeSet(pI, "setHatunWasiAddressAddress", [hwAdd], "pI 008");
  await executeSet(pI, "setTatacuyAddress", [ttc], "pI 009");
  await executeSet(pI, "setWiracochaAddress", [wir], "pI 010");
  await executeSet(pI, "setAddPAController", [pacAdd], "pI 011");
  await executeSet(pI, "setPachaCuyTokenAddress", [pcuyAdd], "pI 012");

  // HATUN WASI
  var hw = hatunWasi;
  var nftAdd = nftProducerPachacuy.address;
  await executeSet(hw, "grantRole", [game_manager, nftAdd], "hw 001");

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Final setting finished!");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");

  // Verify smart contracts
  if (!process.env.HARDHAT_NETWORK) return;

  await verify(randomGeneratorImp, "RNG");
  await verify(purchaseAContImp, "Purchase AC");
  await verify(nftProducerPachacuyImp, "Nft P.");
  await verify(tatacuyImp, "Tatacuy");
  await verify(wiracochaImp, "Wiracocha");
  await verify(pachacuyTokenImp, "Pachacuy token");
  await verify(chakraImp, "Chakra");
  await verify(pachacuyInfoImp, "Pachacuy Info");
  await verify(hatunWasiImp, "Hatun Wasi");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Verification of smart contracts finished");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
}

async function upgrade() {
  // upgrading
  // var RNGAddress = "0x4c8545746F51B5a99AfFE5cd7c79364506fA1d7b";
  // const RandomNumberGenerator = await gcf("RandomNumberGenerator");
  // await upgrades.upgradeProxy(RNGAddress, RandomNumberGenerator);

  // var PACAddress = "0x1509A051E5B91aAa3dE22Ae22D119C8f1Cd3DA80";
  // const PurchaseAssetController = await gcf("PurchaseAssetController");
  // await upgrades.upgradeProxy(PACAddress, PurchaseAssetController);

  // var NFTPAddress = "0xd991d1c6e5c669b8aec320816726a32e69b3db42";
  // const NftProducerPachacuy = await gcf("NftProducerPachacuy");
  // await upgrades.upgradeProxy(NFTPAddress, NftProducerPachacuy);

  var TatacuyAddress = "0xd09Eb12047905B6C4Ec9f445D6871346645c1e8c";
  const Tatacuy = await gcf("Tatacuy");
  await upgrades.upgradeProxy(TatacuyAddress, Tatacuy);

  // var WiracochaAddress = "0xa106BFC5387939DeA7d1EEf4d7bE008543174B1d";
  // const WiracochaContract = await gcf("Wiracocha");
  // await upgrades.upgradeProxy(WiracochaAddress, WiracochaContract);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// upgrade()
// resetOngoingTransaction()
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
