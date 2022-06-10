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
  businessesPrice,
  businessesKey,
} = require("../js-utils/helpers");
var pe = ethers.utils.parseEther;

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
   * - pI 013 - setNftProducerAddress
   * - pI 014 - setMisayWasiAddress
   * - pI 015 - setGuineaPigAddress
   * - pI 016 - setRandomNumberGAddress
   * - pI 017 - setBinarySearchAddress
   * - pI 018 - setPachaAddress
   * - pI 019 - setQhatuWasiAddress
   * - pI 020 - setBusinessesPrice(_prices, _types)
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
   * 3. rng 003 - Add Misay Wasi sc within the whitelist of Random Number Generator
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
   * 7. PAC 007 grantRole money_transfer to misay wasi
   * 7. PAC 008 grantRole money_transfer to qhatu wasi
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
   * nftP 004 - grant game_role to Misay Wasi
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
  var PachaCuyToken, pachaCuyToken, pachacuyTokenImp;
  if (process.env.HARDHAT_NETWORK) {
    PachaCuyToken = await gcf("PachaCuyToken");
    pachaCuyToken = await dp(
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
    pachacuyTokenImp = await getImplementation(pachaCuyToken);
    console.log("PachaCuyToken Imp:", pachacuyTokenImp);
  }

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

  /**
   * MISAY WASI
   * 1. msws 001 - setPachacuyInfoAddress
   * 2. msws 002 - grant game_manager role to nftProducer
   * 3. msws 003 - grant game_manager role to relayer
   * 4. msws 004 - grant RNG_GENERATOR role to RNG sc
   */
  var MisayWasi = await gcf("MisayWasi");
  var misayWasi = await dp(MisayWasi, [], {
    kind: "uups",
  });
  await misayWasi.deployed();
  console.log("MisayWasi Proxy:", misayWasi.address);
  var misayWasiImp = await getImplementation(misayWasi);
  console.log("MisayWasi Imp:", misayWasiImp);

  /**
   * GUINEA PIG
   * 1. gp 001 - setPachacuyInfoAddress
   * 2. gp 002 - give role_manager to nftProducer
   */
  var GuineaPig = await gcf("GuineaPig");
  var guineaPig = await dp(GuineaPig, [], {
    kind: "uups",
  });
  await guineaPig.deployed();
  console.log("GuineaPig Proxy:", guineaPig.address);
  var guineaPigImp = await getImplementation(guineaPig);
  console.log("GuineaPig Imp:", guineaPigImp);

  /**
   * Binary Search
   */
  var BinarySearch = await gcf("BinarySearch");
  var binarySearch = await dp(BinarySearch, [], {
    kind: "uups",
  });
  await binarySearch.deployed();
  console.log("BinarySearch Proxy:", binarySearch.address);
  var binarySearchImp = await getImplementation(binarySearch);
  console.log("BinarySearch Imp:", binarySearchImp);

  /**
   * PACHA
   * 1. pc 001 - set pachacuyInfo address
   * 2. pc 002 - gives game_manager to nft producer
   */
  var Pacha = await gcf("Pacha");
  var pacha = await dp(Pacha, [], {
    kind: "uups",
  });
  await pacha.deployed();
  console.log("Pacha Proxy:", pacha.address);
  var pachaImp = await getImplementation(pacha);
  console.log("Pacha Imp:", pachaImp);

  /**
   * QHATU WASI
   * 1. qw 001 - set pachacuyInfo address
   * 2. qw 002 - gives game_manager role to nft producer
   */
  var QhatuWasi = await gcf("QhatuWasi");
  var qhatuWasi = await dp(QhatuWasi, [], {
    kind: "uups",
  });
  await qhatuWasi.deployed();
  console.log("Qhatu Wasi Proxy:", qhatuWasi.address);
  var qhatuWasiImp = await getImplementation(qhatuWasi);
  console.log("Qhatu Wasi Imp:", qhatuWasiImp);

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Finish Setting up Smart Contracts");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");

  // RANDOM NUMBER GENERATOR
  var rng = randomNumberGenerator;
  var pacAdd = purchaseAssetController.address;
  var ttAdd = tatacuy.address;
  var mswsAdd = misayWasi.address;
  await executeSet(rng, "addToWhiteList", [pacAdd], "rng 001");
  await executeSet(rng, "addToWhiteList", [ttAdd], "rng 002");
  await executeSet(rng, "addToWhiteList", [mswsAdd], "rng 003");

  // PURCHASE ASSET CONTROLLER
  var pac = purchaseAssetController;
  var nftPAdd = nftProducerPachacuy.address;
  var pCuyAdd;
  if (process.env.HARDHAT_NETWORK) pCuyAdd = pachaCuyToken.address;
  else pCuyAdd = nftProducerPachacuy.address;
  var rngAdd = randomNumberGenerator.address;
  var ttAdd = tatacuy.address;
  var wAdd = wiracocha.address;
  var pIAdd = pachacuyInfo.address;
  var mswsAdd = misayWasi.address;
  var qwAdd = qhatuWasi.address;
  await executeSet(pac, "setNftPAddress", [nftPAdd], "PAC 001");
  await executeSet(pac, "setPcuyTokenAddress", [pCuyAdd], "PAC 002");
  await executeSet(pac, "grantRole", [rng_generator, rngAdd], "PAC 003");
  await executeSet(pac, "grantRole", [money_transfer, ttAdd], "PAC 004");
  await executeSet(pac, "grantRole", [money_transfer, wAdd], "PAC 005");
  await executeSet(pac, "setPachacuyInfoAddress", [pIAdd], "PAC 006");
  await executeSet(pac, "grantRole", [money_transfer, mswsAdd], "PAC 007");
  await executeSet(pac, "grantRole", [money_transfer, qwAdd], "PAC 008");

  // NFT PRODUCER
  var nftP = nftProducerPachacuy;
  var pacAdd = purchaseAssetController.address;
  var ttAdd = tatacuy.address;
  var wAd = wiracocha.address;
  var pIAdd = pachacuyInfo.address;
  var mswsAdd = misayWasi.address;
  await executeSet(nftP, "grantRole", [minter_role, pacAdd], "nftP 001");
  await executeSet(nftP, "setPachacuyInfoaddress", [pIAdd], "nftP 002");
  await executeSet(nftP, "grantRole", [game_manager, pacAdd], "nftP 003");
  await executeSet(nftP, "grantRole", [game_manager, mswsAdd], "nftP 004");

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
  var pCuyAdd;
  if (process.env.HARDHAT_NETWORK) pCuyAdd = pachaCuyToken.address;
  else pCuyAdd = nftProducerPachacuy.address;
  var nftAdd = nftProducerPachacuy.address;
  var mswsAdd = misayWasi.address;
  var gpAdd = guineaPig.address;
  var rngAdd = randomNumberGenerator.address;
  var pcAdd = pacha.address;
  var qtwsAdd = qhatuWasi.address;
  var bsAdd = binarySearch.address;
  var Ps = businessesPrice;
  var Ts = businessesKey;
  await executeSet(pI, "setChakraAddress", [chakra.address], "pI 001");
  await executeSet(pI, "setPoolRewardAddress", [wallet], "pI 002");
  await executeSet(pI, "setHatunWasiAddressAddress", [hwAdd], "pI 008");
  await executeSet(pI, "setTatacuyAddress", [ttc], "pI 009");
  await executeSet(pI, "setWiracochaAddress", [wir], "pI 010");
  await executeSet(pI, "setAddPAController", [pacAdd], "pI 011");
  await executeSet(pI, "setPachaCuyTokenAddress", [pCuyAdd], "pI 012");
  await executeSet(pI, "setNftProducerAddress", [nftAdd], "pI 013");
  await executeSet(pI, "setMisayWasiAddress", [mswsAdd], "pI 014");
  await executeSet(pI, "setGuineaPigAddress", [gpAdd], "pI 015");
  await executeSet(pI, "setRandomNumberGAddress", [rngAdd], "pI 016");
  await executeSet(pI, "setBinarySearchAddress", [bsAdd], "pI 017");
  await executeSet(pI, "setPachaAddress", [pcAdd], "pI 018");
  await executeSet(pI, "setQhatuWasiAddress", [qtwsAdd], "pI 019");
  await executeSet(pI, "setBusinessesPrice", [Ps, Ts], "pI 020");

  // HATUN WASI
  var hw = hatunWasi;
  var nftAdd = nftProducerPachacuy.address;
  await executeSet(hw, "grantRole", [game_manager, nftAdd], "hw 001");

  // GUINEA PIG
  var gp = guineaPig;
  var nftAdd = nftProducerPachacuy.address;
  var pcIAdd = pachacuyInfo.address;
  await executeSet(gp, "setPachacuyInfoAddress", [pcIAdd], "gp 001");
  await executeSet(gp, "grantRole", [game_manager, nftAdd], "gp 002");

  // MISAY WASI
  var msws = misayWasi;
  var nftAdd = nftProducerPachacuy.address;
  var pcIadd = pachacuyInfo.address;
  var rel = process.env.RELAYER_ADDRESS_BSC_TESTNET;
  var rngAdd = randomNumberGenerator.address;
  await executeSet(msws, "setPachacuyInfoAddress", [pcIadd], "msws 001");
  await executeSet(msws, "grantRole", [game_manager, nftAdd], "msws 002");
  await executeSet(msws, "grantRole", [game_manager, rel], "msws 003");
  await executeSet(msws, "grantRole", [rng_generator, rngAdd], "msws 004");

  // BINARY SEARCH

  // PACHA
  var pc = pacha;
  var pcIadd = pachacuyInfo.address;
  var nftAdd = nftProducerPachacuy.address;
  await executeSet(pc, "setPachacuyInfoAddress", [pcIadd], "pc 001");
  await executeSet(pc, "grantRole", [game_manager, nftAdd], "pc 002");

  // QHATU WASI
  var qw = qhatuWasi;
  var pcIadd = pachacuyInfo.address;
  var nftAdd = nftProducerPachacuy.address;
  await executeSet(qw, "setPachacuyInfoAddress", [pcIadd], "qw 001");
  await executeSet(qw, "grantRole", [game_manager, nftAdd], "qw 002");

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
  await verify(misayWasiImp, "Misay Wasi");
  await verify(guineaPigImp, "Guinea Pig");
  await verify(binarySearchImp, "Binary Search");
  await verify(pachaImp, "Pacha");
  await verify(qhatuWasiImp, "Qhatu Wasi");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Verification of smart contracts finished");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
}

async function upgrade() {
  // upgrading
  // var PachacuyInfoAddress = "0x72d620EA947cFE5fceDf0FF94Dc9A0Fa498C7cc7";
  // var PachacuyInfo = await ethers.getContractFactory("PachacuyInfo");
  // var pachacuyInfo = await PachacuyInfo.attach(PachacuyInfoAddress);
  // await pachacuyInfo.updateInformationByRank(0, 1000, 50, 30);

  // await pachacuyInfo.updateInformationByRank(1, 2000, 120, 32);
  // await pachacuyInfo.updateInformationByRank(2, 3000, 140, 33);
  // await pachacuyInfo.updateInformationByRank(3, 4000, 160, 35);
  // await pachacuyInfo.updateInformationByRank(4, 5000, 180, 36);
  // await pachacuyInfo.updateInformationByRank(5, 6000, 200, 38);
  // await pachacuyInfo.updateInformationByRank(6, 7000, 220, 40);
  // await pachacuyInfo.updateInformationByRank(7, 8000, 240, 42);
  // await pachacuyInfo.updateInformationByRank(8, 9000, 260, 44);
  // await pachacuyInfo.updateInformationByRank(9, 10000, 280, 47);

  // var PachaCuyTokenAddress = "0xbf5F94350d52390290aA032b96F6FC971AeE70E9";
  // const PachaCuyToken = await gcf("PachaCuyToken");
  // await upgrades.upgradeProxy(PachaCuyTokenAddress, PachaCuyToken);

  // var RNGAddress = "0x4c8545746F51B5a99AfFE5cd7c79364506fA1d7b";
  // const RandomNumberGenerator = await gcf("RandomNumberGenerator");
  // await upgrades.upgradeProxy(RNGAddress, RandomNumberGenerator);

  // var PACAddress = "0x1509A051E5B91aAa3dE22Ae22D119C8f1Cd3DA80";
  // const PurchaseAssetController = await gcf("PurchaseAssetController");
  // await upgrades.upgradeProxy(PACAddress, PurchaseAssetController);

  // var GuineaPigAddress = "0xbB528C3ba24647D710b667B439d5e84D7e35B7bc";
  // const GuineaPig = await gcf("GuineaPig");
  // await upgrades.upgradeProxy(GuineaPigAddress, GuineaPig);

  // var PachaAddress = "0x34Df8bA6C7cE58708aDfd2e9137b573FD4Cd7d76";
  // const Pacha = await gcf("Pacha");
  // await upgrades.upgradeProxy(PachaAddress, Pacha);

  // var WiracochaAddress = "0xf08E3E310562a355E264420917dcCD352b9005b9";
  // const Wiracocha = await gcf("Wiracocha");
  // await upgrades.upgradeProxy(WiracochaAddress, Wiracocha);

  // var HatunWasiAddress = "0x0697473655bb97F27d5325d76b528155eC9FB9c7";
  // const HatunWasi = await gcf("HatunWasi");
  // await upgrades.upgradeProxy(HatunWasiAddress, HatunWasi);

  // var TatacuyAddress = "0xD6cDFb590364E478AB3151Edc0180ebf82Bb456F";
  // const Tatacuy = await gcf("Tatacuy");
  // await upgrades.upgradeProxy(TatacuyAddress, Tatacuy);

  // var NFTPAddress = "0x27B5733C942B20457371c1B6bbcaD2F8B5d07576";
  // const NftProducerPachacuy = await gcf("NftProducerPachacuy");
  // await upgrades.upgradeProxy(NFTPAddress, NftProducerPachacuy);

  // var WiracochaAddress = "0xA5100bE10f9e9da4cD1bA33553Fe119861E11a27";
  // const Wiracocha = await gcf("Wiracocha");
  // await upgrades.upgradeProxy(WiracochaAddress, Wiracocha);

  // var ChakraAddress = "0xab87082eCac2A7D4fcAB8Fa8f097C9C4F75E05D1";
  // const Chakra = await gcf("Chakra");
  // await upgrades.upgradeProxy(ChakraAddress, Chakra);

  var PachaCuyTokenAddress = "0x914C617CB3A1C075F9116734A53FfbCF5CeD6CA9";
  var PachaCuyToken = await gcf("PachaCuyToken");
  var pachaCuyToken = await PachaCuyToken.attach(PachaCuyTokenAddress);
  var wallets = [
    "0xb8fF16Af207ce357E5A53103D5789c4b1c103B61", // 0
    "0x3dFFC99BFD24bA180a114a4b7072998508a5176c",
    "0xfAE9B5c5a4Ed1292F039D78d775CC2F343abaf92",
    "0xEa206afF5776fe17CF0bd117ac9818847e727776",
    "0xE2F557575e55fcc816a8ac3ACb99672147E7E3E3",
    "0x15Bfec909Fc3643618985d96a09860f98fB733fA",
    "0x243E3C2704DDa9d27b87aBf8b85816D34849AB30",
    "0x718429DDe591a305610a664c7046664422095ac3",
    "0x800C44906Fe05B66A7276930894efF2a4cA348CE", // puffy
    "0x2203Ba9Be40AbB782A6b0FA1E3CdFd707CF57364", // 7 // forky
  ];

  var walletsTesters = [
    "0x914C617CB3A1C075F9116734A53FfbCF5CeD6CA9", // 0
    "0x490fEfdA8713053B5aD38d0475309ba7a54F099a",
    "0xA7d52F6b2942d3238F3D0a1BC8FEaBf48bab4ed6",
    "0x1C7Dd5D663EDBFDdaA1162f8B0039D590a4dEd6b",
    "0x7959De1eBcCc4b4433F5FcDB9460ba49b3daC426",
    "0xd7E5c8A7f40a83CdFe3b7eee93323F6040D35126",
    "0x567f259B5c8e8100687608F8e900DFBD0b308Cc0", // 6
  ];
  // Testers
  await pachaCuyToken.send(walletsTesters[0], pe("50"), "0x", {
    gasLimit: "1000000",
  });
  console.log("Enviado");
  await pachaCuyToken.send(walletsTesters[1], pe("50"), "0x", {
    gasLimit: "1000000",
  });
  console.log("Enviado");
  await pachaCuyToken.send(walletsTesters[2], pe("50"), "0x", {
    gasLimit: "1000000",
  });
  console.log("Enviado 2");
  await pachaCuyToken.send(walletsTesters[3], pe("50"), "0x", {
    gasLimit: "1000000",
  });
  console.log("Enviado");
  await pachaCuyToken.send(walletsTesters[4], pe("50"), "0x", {
    gasLimit: "1000000",
  });
  console.log("Enviado");
  await pachaCuyToken.send(walletsTesters[5], pe("50"), "0x", {
    gasLimit: "1000000",
  });
  console.log("Enviado");
  await pachaCuyToken.send(walletsTesters[6], pe("50"), "0x", {
    gasLimit: "1000000",
  });
  console.log("Enviado 6");

  // await pachaCuyToken.send(wallets[0], pe("50000"), "0x");
  // await pachaCuyToken.send(wallets[1], pe("50000"), "0x");
  // await pachaCuyToken.send(wallets[2], pe("50000"), "0x");
  // await pachaCuyToken.send(wallets[3], pe("50000"), "0x");
  // await pachaCuyToken.send(wallets[4], pe("50000"), "0x");
  // await pachaCuyToken.send(wallets[5], pe("50000"), "0x");
  // await pachaCuyToken.send(wallets[6], pe("50000"), "0x");
  // await pachaCuyToken.send(wallets[7], pe("50000"), "0x");
  // var [owner] = await ethers.getSigners();

  // var PachaCuyToken, pachaCuyToken, pachacuyTokenImp;
  // var purchaseAssetController = "0xe8A25f2A8f992bfe250f43ab29f2EBec6E27C46b";
  // if (process.env.HARDHAT_NETWORK) {
  //   PachaCuyToken = await gcf("PachaCuyToken");
  //   pachaCuyToken = await dp(
  //     PachaCuyToken,
  //     [
  //       owner.address,
  //       owner.address,
  //       owner.address,
  //       owner.address,
  //       owner.address,
  //       [purchaseAssetController],
  //     ],
  //     {
  //       kind: "uups",
  //     }
  //   );
  //   await pachaCuyToken.deployed();
  //   console.log("PachaCuyToken Proxy:", pachaCuyToken.address);
  //   pachacuyTokenImp = await getImplementation(pachaCuyToken);
  //   console.log("PachaCuyToken Imp:", pachacuyTokenImp);
  // }

  // // PAC
  // var PurchaseAssetControllerAddress =
  //   "0xe8A25f2A8f992bfe250f43ab29f2EBec6E27C46b";
  // var PurchaseAssetController = await gcf("PurchaseAssetController");
  // var purchaseAssetController = await PurchaseAssetController.attach(
  //   PurchaseAssetControllerAddress
  // );
  // var pac = purchaseAssetController;
  // var pCuyAdd = pachaCuyToken.address;
  // await executeSet(pac, "setPcuyTokenAddress", [pCuyAdd], "PAC 002");

  // // Pachacuy Info
  // var PachacuyInfoAddress = "0x72d620EA947cFE5fceDf0FF94Dc9A0Fa498C7cc7";
  // var PachacuyInfo = await gcf("PachacuyInfo");
  // var pachacuyInfo = await PachacuyInfo.attach(PachacuyInfoAddress);
  // var pI = pachacuyInfo;
  // await executeSet(pI, "setPachaCuyTokenAddress", [pCuyAdd], "pI 012");

  // // Verify
  // await verify(pachacuyTokenImp, "Pachacuy token");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
upgrade()
  // resetOngoingTransaction()
  // main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
