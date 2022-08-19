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
  toBytes32,
  callSequenceAgnostic,
  manager_vesting,
} = require("../js-utils/helpers");
var { callSequence } = require("../js-utils/helpterTesting");

var pe = ethers.utils.parseEther;
var polygon = true;
var rinkeby = false;
var nftData;

var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var bn = ethers.BigNumber.from;
// var NET = "MUMBAI";
var NET = "POLYGON";

async function main() {
  var [owner] = await ethers.getSigners();
  if (process.env.HARDHAT_NETWORK) upgrades.silenceWarnings();
  // /**
  //  * BUSINESS WALLET SMART CONTRACT
  //  */
  // var BusinessWallet = await gcf("BusinessWallet");
  // var businessWallet = await dp(BusinessWallet, [], {
  //   kind: "uups",
  // });
  // await businessWallet.deployed();
  // console.log("BusinessWallet Proxy:", businessWallet.address);
  // var businessWalletImp = await getImplementation(businessWallet);
  // console.log("BusinessWallet Imp:", businessWalletImp);

  // /**
  //  * PACHACUY INFORMATION
  //  * - pI 001 - set chakra address
  //  * - pI 002 - set business wallet address
  //  * - pI 003 - DEFAULT - set purchase tax
  //  * - pI 004 - DEFAULT - set minimum sami points per box
  //  * - pI 005 - DEFAULT - set maximum sami points per box
  //  * - pI 006 - DEFAULT - set total food per chakra
  //  * - pI 007 - DEFAULT set exchange rate pcuy to sami
  //  * - pI 008 - set hatun wasi address
  //  * - pI 009 - setTatacuyAddress
  //  * - pI 010 - setWiracochaAddress
  //  * - pI 011 - set Purchase A C A ddress
  //  * - pI 012 - setPachaCuyTokenAddress
  //  * - pI 013 - setNftProducerAddress
  //  * - pI 014 - setMisayWasiAddress
  //  * - pI 015 - setGuineaPigAddress
  //  * - pI 016 - setRandomNumberGAddress
  //  * - pI 017 - setBinarySearchAddress
  //  * - pI 018 - setPachaAddress
  //  * - pI 019 - setQhatuWasiAddress
  //  * - pI 020 - setBusinessesPrice(_prices, _types)
  //  */
  // var PachacuyInfo = await gcf("PachacuyInfo");
  // var pachacuyInfo = await dp(
  //   PachacuyInfo,
  //   [
  //     pachacuyInfoForGame.maxSamiPoints,
  //     pachacuyInfoForGame.boxes,
  //     pachacuyInfoForGame.affectation,
  //   ],
  //   {
  //     kind: "uups",
  //   }
  // );
  // await pachacuyInfo.deployed();
  // console.log("PachacuyInfo Proxy:", pachacuyInfo.address);
  // var pachacuyInfoImp = await getImplementation(pachacuyInfo);
  // console.log("PachacuyInfo Imp:", pachacuyInfoImp);

  // /**
  //  * RANDOM NUMBER GENERATOR
  //  * 1. Set Random Number Generator address as consumer in VRF subscription
  //  * 2. rng 001 - Add PurchaseAssetController sc within the whitelist of Random Number Generator
  //  * 2. rng 002 - Add Tatacuy sc within the whitelist of Random Number Generator
  //  * 3. rng 003 - Add Misay Wasi sc within the whitelist of Random Number Generator
  //  * 3. rng 004 - setKeyHash
  //  * 3. rng 005 - setvrfCoordinator
  //  * 3. rng 006 - setlinkToken
  //  * 3. rng 007 - setSubscriptionId
  //  */
  // const RandomNumberGenerator = await gcf("RandomNumberGenerator");
  // const randomNumberGenerator = await dp(RandomNumberGenerator, [], {
  //   kind: "uups",
  // });
  // await randomNumberGenerator.deployed();
  // console.log("RandomNumberGenerator Proxy:", randomNumberGenerator.address);
  // var randomGeneratorImp = await getImplementation(randomNumberGenerator);
  // console.log("RandomNumberGenerator Imp:", randomGeneratorImp);

  // /**
  //  * Purchase Asset Controller
  //  * 1. Pass within the initialize the ranmdom number generator address
  //  * 2. PAC 001 setNftPAddress
  //  * 3. PAC 002 set Pcuy token address
  //  * 4. PAC 003 grant role rng_generator to the random number generator sc
  //  * 5. PAC 004 grant role money_transfer to Tatacuy
  //  * 6. PAC 005 grant role money_transfer to Wiracocha
  //  * 7. PAC 006 set Pachacuy Info address with setPachacuyInfoAddress
  //  * 7. PAC 007 grantRole money_transfer to misay wasi
  //  * 7. PAC 008 grantRole money_transfer to qhatu wasi
  //  */
  // const PurchaseAssetController = await gcf("PurchaseAssetController");
  // const purchaseAssetController = await dp(
  //   PurchaseAssetController,
  //   [randomNumberGenerator.address, businessWallet.address],
  //   {
  //     kind: "uups",
  //   }
  // );
  // await purchaseAssetController.deployed();
  // console.log("PurchaseAC Proxy:", purchaseAssetController.address);
  // var purchaseAContImp = await getImplementation(purchaseAssetController);
  // console.log("PurchaseAC Imp:", purchaseAContImp);

  // /**
  //  * NFT Producer
  //  * nftP 001 - Grant Mint roles to PurchaseAssetController
  //  * nftP 002 - set setPachacuyInfoaddress
  //  * nftP 003 - grant game_role to PurchaseAssetController
  //  * nftP 004 - grant game_role to Misay Wasi
  //  * nftP 005 - grant game_role to Pacha
  //  * nftP 006 - Inlcude all smart contracts for burning
  //  */
  // var name = "In-game NFT Pachacuy";
  // var symbol = "NFTGAMEPCUY";
  // const NftProducerPachacuy = await gcf("NftProducerPachacuy");
  // const nftProducerPachacuy = await dp(NftProducerPachacuy, [name, symbol], {
  //   kind: "uups",
  // });
  // await nftProducerPachacuy.deployed();
  // console.log("NftProducerPachacuy Proxy:", nftProducerPachacuy.address);
  // var nftProducerPachacuyImp = await getImplementation(nftProducerPachacuy);
  // console.log("NftProducerPachacuy Imp:", nftProducerPachacuyImp);

  // /**
  //  * GUINEA PIG
  //  * 1. gp 001 - setPachacuyInfoAddress
  //  * 2. gp 002 - give role_manager to nftProducer
  //  */
  // var GuineaPig = await gcf("GuineaPig");
  // var guineaPig = await dp(GuineaPig, [], {
  //   kind: "uups",
  // });
  // await guineaPig.deployed();
  // console.log("GuineaPig Proxy:", guineaPig.address);
  // var guineaPigImp = await getImplementation(guineaPig);
  // console.log("GuineaPig Imp:", guineaPigImp);

  // /**
  //  * PACHA
  //  * 1. pc 001 - set pachacuyInfo address
  //  * 2. pc 002 - gives game_manager to nft producer
  //  */
  // var Pacha = await gcf("Pacha");
  // var pacha = await dp(Pacha, [], {
  //   kind: "uups",
  // });
  // await pacha.deployed();
  // console.log("Pacha Proxy:", pacha.address);
  // var pachaImp = await getImplementation(pacha);
  // console.log("Pacha Imp:", pachaImp);

  // /**
  //  * VESTING
  //  */
  // var Vesting = await gcf("Vesting");
  // var vesting = await dp(Vesting, [], {
  //   kind: "uups",
  // });
  // await vesting.deployed();
  // console.log("Vesting Proxy:", vesting.address);
  // var vestingImp = await getImplementation(vesting);
  // console.log("Vesting Imp:", vestingImp);

  // /**
  //  * Pachacuy Token PCUY
  //  * 1. Gather all operators and pass it to the initialize
  //  * // Distribution:         (M)
  //    // VESTING               24.5
  //    // PUBLIC SALE           29.5
  //    // PACHACUY  REWARDS     30
  //    // PROOF OF HOLD         2
  //    // PACHACUY EVOLUTION    14
  //    // -------------------------
  //    // TOTAL                 100
  //  */
  // var PachaCuyToken, pachaCuyToken, pachacuyTokenImp;
  // PachaCuyToken = await gcf("PachaCuyToken");
  // pachaCuyToken = await PachaCuyToken.deploy(
  //   vesting.address, // _vesting
  //   owner.address, // _publicSale
  //   owner.address, // _gameRewards
  //   owner.address, // _proofOfHold
  //   owner.address, // _pachacuyEvolution
  //   [purchaseAssetController.address]
  // );
  // await pachaCuyToken.deployed();
  // console.log("PachaCuyToken Proxy:", pachaCuyToken.address);
  // pachacuyTokenImp = pachaCuyToken.address;

  var BusinessWalletAddress = "0x176b7F978236862288fa95F47f3997313eBE3021";
  var BusinessWallet = await gcf("BusinessWallet");
  var businessWallet = await BusinessWallet.attach(BusinessWalletAddress);
  var PachacuyInfoAddress = "0xf20750A7A2Ccc4c6c3d26a44454d36EaF4eE897b";
  var PachacuyInfo = await gcf("PachacuyInfo");
  var pachacuyInfo = await PachacuyInfo.attach(PachacuyInfoAddress);
  var RandomNumberGeneratorAddress =
    "0x1141daC8e94a7134e831Bc44A3646881C78F51c8";
  var RandomNumberGenerator = await gcf("RandomNumberGenerator");
  var randomNumberGenerator = await RandomNumberGenerator.attach(
    RandomNumberGeneratorAddress
  );
  var PurchaseAssetControllerAddress =
    "0xab8731881f248e6852728b9E36d9EbfE3468FcE7";
  var PurchaseAssetController = await gcf("PurchaseAssetController");
  var purchaseAssetController = await PurchaseAssetController.attach(
    PurchaseAssetControllerAddress
  );
  var NftProducerPachacuyAddress = "0xb34112A4371ed3aFa66cF578aBAC78941326E6fb";
  var NftProducerPachacuy = await gcf("NftProducerPachacuy");
  var nftProducerPachacuy = await NftProducerPachacuy.attach(
    NftProducerPachacuyAddress
  );
  var GuineaPigAddress = "0x9DB35f5EA92dff63709d79398bABb6DBF1F4d6C4";
  var GuineaPig = await gcf("GuineaPig");
  var guineaPig = await GuineaPig.attach(GuineaPigAddress);
  var PachaAddress = "0x0a719A5D9A45De4A73C10b19c60050df6F3BA2e3";
  var Pacha = await gcf("Pacha");
  var pacha = await Pacha.attach(PachaAddress);
  var VestingAddress = "0x39400fA10eAd44E551d3a76Fb1F1540618141730";
  var Vesting = await gcf("Vesting");
  var vesting = await Vesting.attach(VestingAddress);
  var PachaCuyTokenAddress = "0x6112aDA65b4A4e7Bf36Dfc2Eec05C116bd51F065";
  var PachaCuyToken = await gcf("PachaCuyToken");
  var pachaCuyToken = await PachaCuyToken.attach(PachaCuyTokenAddress);

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Finish Setting up Smart Contracts");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");

  var r = [
    "HOLDER_CUY_TOKEN",
    "PRIVATE_SALE_1",
    "PRIVATE_SALE_2",
    "AIRDROP",
    "PACHACUY_TEAM",
    "PARTNER_ADVISOR",
    "MARKETING",
  ];
  var hldrTkns = pe(String(1 * 1000000));
  var mktTkns = pe(String(5 * 1000000));
  var c = [
    hldrTkns, // * HOLDER_CUY_TOKEN     -> 1
    pe(String(1.5 * 1000000)), // * PRIVATE_SALE_1       -> 1.5
    pe(String(0.6 * 1000000)), // * PRIVATE_SALE_2       -> 0.6
    pe(String(1.4 * 1000000)), // * AIRDROP              -> 1.4
    pe(String(10 * 1000000)), // * PACHACUY_TEAM        -> 10
    pe(String(5 * 1000000)), // * PARTNER_ADVISOR      -> 5
    mktTkns, // * MARKETING            -> 5
  ];

  // Vesting
  var ves = vesting;
  var pcuyA = pachaCuyToken.address;
  // await executeSet(ves, "settingVestingStateStructs", [r, c], "ves 001");
  // await executeSet(ves, "setPachaCuyAddress", [pcuyA], "ves 002");

  nftData = [
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bool", "address", "bool", "string", "string"],
      [
        toBytes32("PACHA"),
        true,
        pacha.address,
        true,
        "NFP: location taken",
        "Pacha: Out of bounds",
      ]
    ),
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bool", "address", "bool", "string", "string"],
      [toBytes32("PACHAPASS"), true, pacha.address, true, "", ""]
    ),
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bool", "address", "bool", "string", "string"],
      [
        toBytes32("GUINEAPIG"),
        true,
        guineaPig.address,
        true,
        "NFP: No pacha found",
        "",
      ]
    ),
  ];

  var allScAdd = [pacha.address, guineaPig.address];

  // RANDOM NUMBER GENERATOR
  // var rng = randomNumberGenerator;
  // var pacAdd = purchaseAssetController.address;
  // await executeSet(rng, "addToWhiteList", [pacAdd], "rng 001");

  // var khash, vrfC, lnkTkn, id;
  // if (NET === "POLYGON") {
  //   khash =
  //     "0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd";
  //   vrfC = "0xAE975071Be8F8eE67addBC1A82488F1C24858067";
  //   lnkTkn = "0xb0897686c545045afc77cf20ec7a532e3120e0f1";
  //   id = 235;
  //   await executeSet(rng, "setKeyHash", [khash], "rng 004");
  //   await executeSet(rng, "setvrfCoordinator", [vrfC], "rng 005");
  //   await executeSet(rng, "setlinkToken", [lnkTkn], "rng 006");
  //   await executeSet(rng, "setSubscriptionId", [id], "rng 007");
  //   console.log("=== Finished Set Up VRF ===");
  // }

  // PURCHASE ASSET CONTROLLER
  var pac = purchaseAssetController;
  var nftPAdd = nftProducerPachacuy.address;
  var pCuyAdd = pachaCuyToken.address;
  var rngAdd = randomNumberGenerator.address;
  var pIAdd = pachacuyInfo.address;
  // await executeSet(pac, "setNftPAddress", [nftPAdd], "PAC 001");
  // await executeSet(pac, "setPcuyTokenAddress", [pCuyAdd], "PAC 002");
  // await executeSet(pac, "grantRole", [rng_generator, rngAdd], "PAC 003");
  // await executeSet(pac, "setPachacuyInfoAddress", [pIAdd], "PAC 006");
  console.log("=== Finished PAC ===");

  // NFT PRODUCER
  var nftP = nftProducerPachacuy;
  var pacAdd = purchaseAssetController.address;
  var pIAdd = pachacuyInfo.address;
  var pachaAdd = pacha.address;
  // await executeSet(nftP, "grantRole", [minter_role, pacAdd], "nftP 001");
  // await executeSet(nftP, "setPachacuyInfoaddress", [pIAdd], "nftP 002");
  // await executeSet(nftP, "grantRole", [game_manager, pacAdd], "nftP 003");
  // await executeSet(nftP, "grantRole", [game_manager, pachaAdd], "nftP 005");
  // await executeSet(nftP, "setBurnOp", [allScAdd], "nftP 006");
  // await executeSet(nftP, "fillNftsInfo", [nftData], "nftP 007");
  console.log("=== Finished NFTP ===");

  // PACHACUY INFORMATION
  var pI = pachacuyInfo;
  var wallet = businessWallet.address;
  var pacAdd = purchaseAssetController.address;
  var pCuyAdd = pachaCuyToken.address;
  var nftAdd = nftProducerPachacuy.address;
  var gpAdd = guineaPig.address;
  var rngAdd = randomNumberGenerator.address;
  var Ps = businessesPrice;
  var Ts = businessesKey;
  // await executeSet(pI, "setBizWalletAddress", [wallet], "pI 002");
  // await executeSet(pI, "setAddPAController", [pacAdd], "pI 011");
  await executeSet(pI, "setPachaCuyTokenAddress", [pCuyAdd], "pI 012");
  // await executeSet(pI, "setNftProducerAddress", [nftAdd], "pI 013");
  // await executeSet(pI, "setGuineaPigAddress", [gpAdd], "pI 015");
  // await executeSet(pI, "setRandomNumberGAddress", [rngAdd], "pI 016");
  // await executeSet(pI, "setBusinessesPrice", [Ps, Ts], "pI 020");
  console.log("=== Finished PCUYINFO ===");

  // GUINEA PIG
  var gp = guineaPig;
  var nftAdd = nftProducerPachacuy.address;
  var pcIAdd = pachacuyInfo.address;
  // await executeSet(gp, "setPachacuyInfoAddress", [pcIAdd], "gp 001");
  // await executeSet(gp, "grantRole", [game_manager, nftAdd], "gp 002");
  console.log("=== Finished Guinea Pig ===");

  // PACHA
  var pc = pacha;
  var pcIadd = pachacuyInfo.address;
  var nftAdd = nftProducerPachacuy.address;
  // await executeSet(pc, "setPachacuyInfoAddress", [pcIadd], "pc 001");
  // await executeSet(pc, "grantRole", [game_manager, nftAdd], "pc 002");
  console.log("=== Finished PACHA ===");

  // BUSINESSES SMART CONTRACT
  var bz = businessWallet;
  var pcIadd = pachacuyInfo.address;
  // await executeSet(bz, "setPachacuyInfoAddress", [pcIadd], "bz 001");
  console.log("=== Finished BIZ SC ===");

  // TRANSFER to wallets
  var lq = process.env.WALLET_PACHACUY_LIQUIDITY;
  var pr = process.env.WALLET_PACHACUY_POOL_REWARDS;
  var ph = process.env.WALLET_PACHACUY_PROOF_OF_HOLD;
  var pev = process.env.WALLET_PACHACUY_PACHACUY_EVOLUTION;
  var pt = pachaCuyToken.transfer;
  try {
    // await pt(lq, pe(String(295 * 100000)).sub(pe("29.5")));
    // await pt(pr, pe(String(30 * 1000000)).sub(pe("30")));
    // await pt(ph, pe(String(2 * 1000000)).sub(pe("2")));
    // await pt(pev, pe(String(14 * 1000000)).sub(pe("14")));
    await pt(pev, await pachaCuyToken.balanceOf(owner.address));
    console.log("=== Finished Transference ===");
  } catch (error) {
    console.log("Error transfering tokens: " + error);
  }

  // VESTING
  var add = process.env.LENIN_ADMIN_FUNDS;
  var ves = vesting;
  // await executeSet(ves, "grantRole", [manager_vesting, add], "ves 001");
  console.log("=== Finished Grant Vesting ===");

  // VRF
  var url, vrfAddress, id;
  if (NET === "POLYGON") {
    url = process.env.ALCHEMY_POLYGON_URL;
    vrfAddress = "0xAE975071Be8F8eE67addBC1A82488F1C24858067";
    id = 235;
  } else if (NET === "MUMBAI") {
    url = "https://matic-mumbai.chainstacklabs.com";
    vrfAddress = "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed";
    id = 581;
  } else {
    throw new Error("Invalid network");
  }
  var provider = new ethers.providers.JsonRpcProvider(url);
  var signer = await ethers.getSigner();
  var abiVrf = ["function addConsumer(uint64 subId, address consumer)"];
  var vrfC = new ethers.Contract(vrfAddress, abiVrf, provider);
  var rngA = randomNumberGenerator.address;
  // await executeSet(vrfC.connect(signer), "addConsumer", [id, rngA], "VRF 001");
  console.log("=== Finished Add Consumer ===");

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Final setting finished!");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");

  // Verify smart contracts
  return;
  if (!process.env.HARDHAT_NETWORK) return;
  var businessWalletImp = "0xff77328791aa561A68184d19090E5f727639704a";
  var pachacuyInfoImp = "0x79FfB62BB260c0874502dBA2d3Db156eF7FBFbf2";
  var randomGeneratorImp = "0x7F4C2EBCf96017B464Ac1B7AcC6495d80b0c2250";
  var purchaseAContImp = "0x80144322870E995DB7850b81C9dbBa782DcA206c";
  var nftProducerPachacuyImp = "0xc9Fd34bDA1965f2965C5238838EbB230482167B0";
  var guineaPigImp = "0x239B01606c33Ced0914A4Ae4F966E8B902E72416";
  var pachaImp = "0x04d2BB648cFd0b4D728eC6885bf85bc8E970f943";
  var vestingImp = "0x4133a9E38D84D09EBF9eB1941CE05FBDB721e680";

  await verify(businessWalletImp, "RNG");
  await verify(randomGeneratorImp, "RNG");
  await verify(purchaseAContImp, "Purchase AC");
  await verify(nftProducerPachacuyImp, "Nft P.");
  await verify(pachaCuyToken.address, "Pachacuy token", [
    vesting.address,
    owner.address,
    owner.address,
    owner.address,
    owner.address,
    [purchaseAssetController.address],
  ]);
  await verify(pachacuyInfoImp, "Pachacuy Info");
  await verify(guineaPigImp, "Guinea Pig");
  await verify(pachaImp, "Pacha");
  await verify(vestingImp, "Vesting");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Verification of smart contracts finished");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
