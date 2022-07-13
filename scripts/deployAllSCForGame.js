const { upgrades, ethers, hardhatArguments } = require("hardhat");
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
var bn = ethers.BigNumber.from;
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
   * nftP 005 - grant game_role to Pacha
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
  var pachaAdd = pacha.address;
  await executeSet(nftP, "grantRole", [minter_role, pacAdd], "nftP 001");
  await executeSet(nftP, "setPachacuyInfoaddress", [pIAdd], "nftP 002");
  await executeSet(nftP, "grantRole", [game_manager, pacAdd], "nftP 003");
  await executeSet(nftP, "grantRole", [game_manager, mswsAdd], "nftP 004");
  await executeSet(nftP, "grantRole", [game_manager, pachaAdd], "nftP 005");

  // Tatacuy
  var tt = tatacuy;
  var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET_2;
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
  var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET_2;
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
  var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET_2;
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

  // VRF
  var url = "https://matic-mumbai.chainstacklabs.com";
  var provider = new ethers.providers.JsonRpcProvider(url);
  var signer = await ethers.getSigner();
  var vrfAddress = "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed";
  var abiVrf = ["function addConsumer(uint64 subId, address consumer)"];
  var vrfC = new ethers.Contract(vrfAddress, abiVrf, provider);
  var rngA = randomNumberGenerator.address;
  await executeSet(vrfC.connect(signer), "addConsumer", [581, rngA], "VRF 001");

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
  try {
    var PurchaseAssetControllerAddress =
      "0x12ad5406567B3326b6014e4037026963511e763D";
    const PurchaseAssetController = await gcf("PurchaseAssetController");
    await upgrades.upgradeProxy(
      PurchaseAssetControllerAddress,
      PurchaseAssetController
    );
  } catch (error) {
    console.log("Error with PurchaseAssetController", error);
  }
  return;
  try {
    var PachaCuyTokenAddress = "0x829776b2eb5D6588971cabf6186bA39243b83fc0";
    const PachaCuyToken = await gcf("PachaCuyToken");
    var pachaCuyToken = await PachaCuyToken.attach(PachaCuyTokenAddress);
    await pachaCuyToken.setPachacuyInfoAddress(
      "0x1655b030Bad6AB10D44e57bcb3E7e48e29633317"
    );
  } catch (error) {
    console.log("Error with pcuy info add", error);
  }
}

async function resetOngoingTransaction() {
  var wallet = "0xA6B2Fa18d3e746D3012dAbc21e63BcC35E638897";
  var PurchaseAssetControllerAddress =
    "0xD07374655eC9BCD08229D6Ef4Cb1b815fBD25291";
  var PurchaseAssetController = await gcf("PurchaseAssetController");
  var purchaseAssetController = await PurchaseAssetController.attach(
    PurchaseAssetControllerAddress
  );
  await purchaseAssetController.resetOngoingTransactionForAccount(wallet);

  var RandomNumberGeneratorAddress =
    "0x14B0524D9CdBd2098198A6a9e094bbd68974a50B";
  var RandomNumberGenerator = await gcf("RandomNumberGenerator");
  var randomNumberGenerator = await RandomNumberGenerator.attach(
    RandomNumberGeneratorAddress
  );
  await randomNumberGenerator.resetOngoinTransaction(wallet);
}

async function sendTokens() {
  // var PachaCuyTokenAddress = "0x26813E464DA80707B7F24bf19e08Bf876F0f3388"; // alpha
  var PachaCuyTokenAddress = "0x7Bff8A404D571120B38f76467Ef2965DE25babdC"; // dev
  var PachaCuyToken = await gcf("PachaCuyToken");
  var pachaCuyToken = await PachaCuyToken.attach(PachaCuyTokenAddress);
  var wallets = [
    "0x77a033E62057eE1F818f75F703427c07D4A7c1E4", // 0
    "0x3dFFC99BFD24bA180a114a4b7072998508a5176c", // 0
    "0xf6E4f7B1b2f403238DD194EAD252AfB42A47BFe3", // 0
    "0xb8fF16Af207ce357E5A53103D5789c4b1c103B61", // 1
    "0x3dFFC99BFD24bA180a114a4b7072998508a5176c",
    "0xfAE9B5c5a4Ed1292F039D78d775CC2F343abaf92",
    "0xEa206afF5776fe17CF0bd117ac9818847e727776",
    "0xE2F557575e55fcc816a8ac3ACb99672147E7E3E3",
    "0x15Bfec909Fc3643618985d96a09860f98fB733fA",
    "0x243E3C2704DDa9d27b87aBf8b85816D34849AB30",
    "0x718429DDe591a305610a664c7046664422095ac3",
    "0x2D1d94D7941E7e17D7108D3D488399d9858Dff65", // puffy
  ];

  var pc = pachaCuyToken;
  var g = { gasLimit: 1000000 };
  var args = [wallets[0], pe("100000"), "0x", g];
  var t = await executeSet(pc, "send", args, "1");
  var r = await t.wait(1);
  var args = [wallets[1], pe("100000"), "0x", g];
  var t = await executeSet(pc, "send", args, "1");
  var r = await t.wait(1);
  // await executeSet(pcuy, "send", [wallets[1], pe("100000"), "0x", g], "2");
  // await executeSet(pcuy, "send", [wallets[2], pe("100000"), "0x", g], "3");
  // await executeSet(pcuy, "send", [wallets[3], pe("100000"), "0x", g], "4");
  // await executeSet(pcuy, "send", [wallets[4], pe("100000"), "0x", g], "5");
  // await executeSet(pcuy, "send", [wallets[5], pe("100000"), "0x", g], "6");
  // await executeSet(pcuy, "send", [wallets[6], pe("100000"), "0x", g], "7");
  // await executeSet(pcuy, "send", [wallets[7], pe("100000"), "0x", g], "8");
  // await executeSet(pcuy, "send", [wallets[8], pe("100000"), "0x", g], "9");
  // await executeSet(pcuy, "send", [wallets[9], pe("100000"), "0x", g], "10");
  // await executeSet(pcuy, "send", [wallets[10], pe("100000"), "0x", g], "11");
}

function co(address) {
  return { address };
}

async function fixDeployment() {
  var pachacuyInfo = co("0xf2719944395F9Bb18Ec5ba44A4aD4c3De9Ceef30");
  var randomNumberGenerator = co("0x2CCB6bDeA0cEb206D06082E5410D2380dD0e90CC");
  var purchaseAssetController = co(
    "0x470133768f065D39cb8e1393a3E5e40ECf7624Be"
  );
  var nftProducerPachacuy = co("0x38f1BF35F6C40E61411080Ae78bDC1Acb6b4aa24");
  var tatacuy = co("0x7D828E9B4ABa8D5116BcCe9C2752355992B5bB26");
  var wiracocha = co("0xE4e7a8eD6c8c3f3f10f9988EbF03F8504E361884");
  var PachaCuyToken = co("0xe9B20573f51C6B5b38193a044Aa755A81CAcf12c");
  var Chakra = co("0x64CA1bC7AD930f71021B0bE1fC1a9C4e6FcF9736");
  var Hatun = co("0x312fd1D9d42CaB291414705614b5eB24fc8B7Fb4");
  var misayWasi = co("0xc5fb5E474d8D37e3A8B728979113507c35Ad0151");
  var GuineaPig = co("0x957B46Dc236ba40fb2A567AEDc1f8b6EB583A356");
  var BinarySearch = co("0x87dF88Ed85400Af52d06F0bF1B9a91b3094d6dAf");
  var pacha = co("0xFb145B38DCE1feEEe0106326c1BC7c70BB415e98");
  var Qhatu = co("0x06A2e3120581C5935741fA003841C5bCE16E1652");

  var PurchaseAssetControllerAddress =
    "0x470133768f065D39cb8e1393a3E5e40ECf7624Be";
  var PurchaseAssetController = await gcf("PurchaseAssetController");
  var purchaseAssetController = await PurchaseAssetController.attach(
    PurchaseAssetControllerAddress
  );

  var tx = await purchaseAssetController.purchaseLandWithPcuy(3, {
    gasPrice: 100,
    gasLimit: 1000000,
  });
  console.log("sent");
  var res = await tx.wait();
  console.log(res);

  // var NftProducerPachacuyAddress = "0x38f1BF35F6C40E61411080Ae78bDC1Acb6b4aa24";
  // var NftProducerPachacuy = await gcf("NftProducerPachacuy");
  // var nftP = await NftProducerPachacuy.attach(NftProducerPachacuyAddress);
  // var pacAdd = purchaseAssetController.address;
  // var ttAdd = tatacuy.address;
  // var wAd = wiracocha.address;
  // var pIAdd = pachacuyInfo.address;
  // var mswsAdd = misayWasi.address;
  // var pachaAdd = pacha.address;
  // // await executeSet(nftP, "setPachacuyInfoaddress", [pIAdd], "nftP 002");
  // // await executeSet(nftP, "grantRole", [game_manager, pacAdd], "nftP 003");
  // // await executeSet(nftP, "grantRole", [game_manager, mswsAdd], "nftP 004");
  // // await executeSet(nftP, "grantRole", [game_manager, pachaAdd], "nftP 005");
  // var TatacuyAddress = "0x7D828E9B4ABa8D5116BcCe9C2752355992B5bB26";
  // var Tatacuy = await gcf("Tatacuy");
  // var tt = await Tatacuy.attach(TatacuyAddress);
  // var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET;
  // // await executeSet(tt, "grantRole", [game_manager, rel], "tt 001");

  // var GuineaPigAddress = "0x957B46Dc236ba40fb2A567AEDc1f8b6EB583A356";
  // var GuineaPig = await gcf("GuineaPig");
  // var gp = await GuineaPig.attach(GuineaPigAddress);
  // var nftAdd = nftProducerPachacuy.address;
  // var pcIAdd = pachacuyInfo.address;
  // // await executeSet(gp, "setPachacuyInfoAddress", [pcIAdd], "gp 001");

  // var MisayWasiAddress = "0xc5fb5E474d8D37e3A8B728979113507c35Ad0151";
  // var MisayWasi = await gcf("MisayWasi");
  // var msws = await MisayWasi.attach(MisayWasiAddress);
  // var nftAdd = nftProducerPachacuy.address;
  // var pcIadd = pachacuyInfo.address;
  // var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET;
  // var rngAdd = randomNumberGenerator.address;
  // // await executeSet(msws, "grantRole", [rng_generator, rngAdd], "msws 004");

  // var PachaAddress = "0xFb145B38DCE1feEEe0106326c1BC7c70BB415e98";
  // var Pacha = await gcf("Pacha");
  // var pc = await Pacha.attach(PachaAddress);
  // var pcIadd = pachacuyInfo.address;
  // var nftAdd = nftProducerPachacuy.address;
  // // await executeSet(pc, "setPachacuyInfoAddress", [pcIadd], "pc 001");
  // // await executeSet(pc, "grantRole", [game_manager, nftAdd], "pc 002");

  // var QhatuWasiAddress = "0x06A2e3120581C5935741fA003841C5bCE16E1652";
  // var QhatuWasi = await gcf("QhatuWasi");
  // var qw = await QhatuWasi.attach(QhatuWasiAddress);
  // var pcIadd = pachacuyInfo.address;
  // var nftAdd = nftProducerPachacuy.address;
  // await executeSet(qw, "grantRole", [game_manager, nftAdd], "qw 002");
  console.log("finished qws");
  return;
}

async function fixRelayer() {
  var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET_2;

  var TatacuyAddress = "0xA6B3b26fcE99a5Dd8e180c43B8EB98eF6DA493f6";
  var Tatacuy = await gcf("Tatacuy");
  var tt = await Tatacuy.attach(TatacuyAddress);
  var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET_2;
  await executeSet(tt, "grantRole", [game_manager, rel], "tt 001");

  var WiracochaAddress = "0xA645bFdb41c151d3137b825baA31579240F5Bd08";
  var Wiracocha = await gcf("Wiracocha");
  var wi = await Wiracocha.attach(WiracochaAddress);
  await executeSet(wi, "grantRole", [game_manager, rel], "wi 001");

  var MisayWasiAddress = "0x4f1e1E9753b6bdE59E4863417c392838fdB3FC43";
  var MisayWasi = await gcf("MisayWasi");
  var msws = await MisayWasi.attach(MisayWasiAddress);
  await executeSet(msws, "grantRole", [game_manager, rel], "msws 003");
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
upgrade()
  // resetOngoingTransaction()
  // fixDeployment()
  // main()
  // sendTokens()
  // fixRelayer()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

/**
var pacAddress = "0xD07374655eC9BCD08229D6Ef4Cb1b815fBD25291"
var pacAbi = ["function purchaseGuineaPigWithPcuy(uint256 _ix) external"]
var url = "https://matic-mumbai.chainstacklabs.com"
var provider = new ethers.providers.JsonRpcProvider(url)
var contract = new ethers.Contract(pacAddress, pacAbi, provider)
var tx = await contract.connect(await ethers.getSigner()).purchaseGuineaPigWithPcuy(3, {gasLimit: 3000000});
*/
