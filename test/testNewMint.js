const { expect } = require("chai");
const { formatEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
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
  executeSet,
  businessesPrice,
  businessesKey,
  b,
  getDataFromEvent,
  toBytes32,
} = require("../js-utils/helpers");
const { init } = require("../js-utils/helpterTesting");
// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";
var _prefix = "ipfs://QmbbGgo93M6yr5WSUMj53SWN2vC7L6aMS1GZSPNkVRY8e4/";
var testing;
var cw = process.env.WALLET_FOR_FUNDS;
var nftData;

describe("Tesing Pachacuy Game", function () {
  var owner,
    alice,
    bob,
    carl,
    deysi,
    earl,
    fephe,
    gary,
    huidobro,
    custodianWallet;
  var PachacuyInfo,
    RandomNumberGenerator,
    PurchaseAssetController,
    NftProducerPachacuy,
    Tatacuy,
    Wiracocha,
    PachaCuyToken,
    Chakra,
    HatunWasi;
  var pachacuyInfo,
    randomNumberGenerator,
    purchaseAssetController,
    nftProducerPachacuy,
    tatacuy,
    wiracocha,
    pachaCuyToken,
    chakra,
    hatunWasi;
  var MisayWasi,
    misayWasi,
    misayWasiImp,
    GuineaPig,
    guineaPig,
    guineaPigImp,
    BinarySearch,
    binarySearch,
    binarySearchImp,
    Pacha,
    pacha,
    pachaImp,
    QhatuWasi,
    qhatuWasi,
    qhatuWasiImp;
  var PachacuyInfo;
  var pachacuyInfo;
  var gcf = hre.ethers.getContractFactory;
  var dp = upgrades.deployProxy;
  var signers;
  var pe = ethers.utils.parseEther;
  var fe = ethers.utils.formatEther;
  var balanceOf;
  var uuid;

  before(async function () {
    signers = await ethers.getSigners();
    [
      owner,
      alice,
      bob,
      carl,
      deysi,
      earl,
      fephe,
      gary,
      huidobro,
      custodianWallet,
    ] = signers;
    uuid = 0;
  });

  describe("Set Up", async function () {
    it("Initializes all Smart Contracts", async () => {
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
      PachacuyInfo = await gcf("PachacuyInfo");
      pachacuyInfo = await dp(
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
      PachacuyInfo = await gcf("PachacuyInfo");
      pachacuyInfo = await dp(
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

      /**
       * RANDOM NUMBER GENERATOR
       * 1. Set Random Number Generator address as consumer in VRF subscription
       * 2. rng 001 - Add PurchaseAssetController sc within the whitelist of Random Number Generator
       * 2. rng 002 - Add Tatacuy sc within the whitelist of Random Number Generator
       * 3. rng 003 - Add Misay Wasi sc within the whitelist of Random Number Generator
       */
      RandomNumberGenerator = await gcf("RandomNumberV2Mock");
      // RandomNumberGenerator = await gcf("RandomNumberGenerator");
      // randomNumberGenerator = await dp(RandomNumberGenerator, [], {
      // kind: "uups",
      // });
      // await randomNumberGenerator.deployed();
      randomNumberGenerator = await RandomNumberGenerator.deploy();

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
      PurchaseAssetController = await gcf("PurchaseAssetController");
      purchaseAssetController = await dp(
        PurchaseAssetController,
        [randomNumberGenerator.address, process.env.WALLET_FOR_FUNDS],
        {
          kind: "uups",
        }
      );
      await purchaseAssetController.deployed();

      /**
       * NFT Producer
       * nftP 001 - Grant Mint roles to PurchaseAssetController
       * nftP 002 - set setPachacuyInfoaddress
       * nftP 003 - grant game_role to PurchaseAssetController
       * nftP 004 - grant game_role to Misay Wasi
       * nftP 005 - grant game_role to Pacha
       * nftP 006 - Inlcude all smart contracts for burning
       * nftP 007 - Fills nft info fillNftsInfo array
       */
      var name = "In-game NFT Pachacuy";
      var symbol = "NFTGAMEPCUY";
      NftProducerPachacuy = await gcf("NftProducerPachacuy");
      nftProducerPachacuy = await dp(NftProducerPachacuy, [name, symbol], {
        kind: "uups",
      });
      await nftProducerPachacuy.deployed();

      /**
       * Tatacuy
       * 1, tt 001 - Tatacuy must grant game_manager role to relayer bsc testnet
       * 2, tt 002 - Tatacuy must grant game_manager role to Nft producer
       * 3. tt 003 - Grant role rng_generator to the random number generator sc
       * 4. tt 004 - setPachacuyInfoAddress
       *
       */
      Tatacuy = await gcf("Tatacuy");
      tatacuy = await dp(Tatacuy, [randomNumberGenerator.address], {
        kind: "uups",
      });
      await tatacuy.deployed();

      /**
       * Wiracocha
       * 1. wi 001 - Gave game_manager to relayer
       * 2. wi 002 - Gave game_manager to Nft Producer
       * 3. wi 003 - Gave game_manager to Purchase asset contoller
       * 4. wi 004 - setPachacuyInfoAddress
       */
      Wiracocha = await gcf("Wiracocha");
      wiracocha = await dp(Wiracocha, [], {
        kind: "uups",
      });
      await wiracocha.deployed();

      /**
       * Pachacuy Token PCUY
       * 1. Gather all operators and pass it to the initialize
       */
      // PachaCuyToken = await gcf("PachaCuyToken");
      PachaCuyToken = await gcf("ERC777Mock");
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
      balanceOf = b(pachaCuyToken);

      /**
       * CHAKRA
       * 1. ck 002 - Initialize - Pass the info contract address in initialize
       * 2. ck 001 - Grant game_manager role to Nft producer
       */
      Chakra = await gcf("Chakra");
      chakra = await dp(Chakra, [pachacuyInfo.address], {
        kind: "uups",
      });

      await chakra.deployed();

      /**
       * HATUN WASI
       * 1. hw 001 - Grant game_manager role to Nft producer
       */
      HatunWasi = await gcf("HatunWasi");
      hatunWasi = await dp(HatunWasi, [], {
        kind: "uups",
      });

      await hatunWasi.deployed();

      /**
       * MISAY WASI
       * 1. msws 001 - setPachacuyInfoAddress
       * 2. msws 002 - grant game_manager role to nftProducer
       * 3. msws 003 - grant game_manager role to relayer
       * 4. msws 004 - grant RNG_GENERATOR role to RNG sc
       */
      MisayWasi = await gcf("MisayWasi");
      misayWasi = await dp(MisayWasi, [], {
        kind: "uups",
      });
      await misayWasi.deployed();
      misayWasiImp = await getImplementation(misayWasi);

      /**
       * GUINEA PIG
       * 1. gp 001 - setPachacuyInfoAddress
       * 2. gp 002 - give role_manager to nftProducer
       */
      GuineaPig = await gcf("GuineaPig");
      guineaPig = await dp(GuineaPig, [], {
        kind: "uups",
      });
      await guineaPig.deployed();
      guineaPigImp = await getImplementation(guineaPig);

      /**
       * Binary Search
       */
      BinarySearch = await gcf("BinarySearch");
      binarySearch = await dp(BinarySearch, [], {
        kind: "uups",
      });
      await binarySearch.deployed();
      binarySearchImp = await getImplementation(binarySearch);

      /**
       * PACHA
       * 1. pc 001 - set pachacuyInfo address
       * 2. pc 002 - gives game_manager to nft producer
       */
      Pacha = await gcf("Pacha");
      pacha = await dp(Pacha, [], {
        kind: "uups",
      });
      await pacha.deployed();
      pachaImp = await getImplementation(pacha);

      /**
       * QHATU WASI
       * 1. qw 001 - set pachacuyInfo address
       * 2. qw 002 - gives game_manager role to nft producer
       */
      QhatuWasi = await gcf("QhatuWasi");
      qhatuWasi = await dp(QhatuWasi, [], {
        kind: "uups",
      });
      await qhatuWasi.deployed();
      qhatuWasiImp = await getImplementation(qhatuWasi);
    });

    it("Sets up all Smart Contracts", async () => {
      nftData = [
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "bool"],
          [toBytes32("PACHA"), pacha.address, true]
        ),
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "bool"],
          [toBytes32("QHATUWASI"), qhatuWasi.address, true]
        ),
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "bool"],
          [toBytes32("MISAYWASI"), misayWasi.address, true]
        ),
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "bool"],
          [toBytes32("HATUNWASI"), hatunWasi.address, false]
        ),
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "bool"],
          [toBytes32("CHAKRA"), chakra.address, true]
        ),
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "bool"],
          [toBytes32("TATACUY"), tatacuy.address, false]
        ),
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "bool"],
          [toBytes32("WIRACOCHA"), wiracocha.address, false]
        ),
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "bool"],
          [toBytes32("GUINEAPIG"), guineaPig.address, true]
        ),
      ];

      var allScAdd = [
        qhatuWasi.address,
        pacha.address,
        guineaPig.address,
        misayWasi.address,
        hatunWasi.address,
        chakra.address,
        wiracocha.address,
        tatacuy.address,
      ];

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
      var pCuyAdd = pachaCuyToken.address;
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
      await executeSet(nftP, "setBurnOp", [allScAdd], "nftP 006");
      await executeSet(nftP, "fillNftsInfo", [nftData], "nftP 007");

      // Tatacuy
      var tt = tatacuy;
      var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET;
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
      var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET;
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
      var pCuyAdd = pachaCuyToken.address;
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
      var pcIAdd = pachacuyInfo.address;
      await executeSet(hw, "grantRole", [game_manager, nftAdd], "hw 001");
      await executeSet(hw, "setPachacuyInfoAddress", [pcIAdd], "hw 002");

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
      var rel = process.env.RELAYER_ADDRESS_MUMBAI_TESTNET;
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

      // init helper
      testing = init(
        purchaseAssetController,
        pachaCuyToken,
        pachacuyInfo,
        chakra,
        pachacuyInfo,
        guineaPig,
        misayWasi,
        randomNumberGenerator,
        nftProducerPachacuy
      );
    });
  });

  describe("Pacha", () => {
    it("Purchase land", async () => {
      await pachaCuyToken.mint(alice.address, pe("50000"));
      await testing.purchaseLand(alice, [1, ++uuid]); // uuid 1 pacha
    });
  });

  describe("Qhatu Wasi", () => {
    it("Purhcase", async () => {
      await testing.purchaseQhatuWasi(alice, [1, ++uuid]); // uuid 2 qhatu wasi
    });
  });

  describe("Misay Wasi", () => {
    it("Purchase", async () => {
      await testing.purchaseMisaywasi(alice, [++uuid, 1]); // uuid 3 misay wasi
    });
  });

  describe("Hatun Wasi", () => {
    it("Mint", async () => {
      await testing.mintHatunWasi(alice, [1, ++uuid]); // uuid 4 hatun wasi
    });
  });

  describe("Chakra", () => {
    it("Purchase", async () => {
      await testing.purchaseChakra(alice, [1, ++uuid]); // uuid 5 chakra
    });
  });

  describe("Tatacuy", () => {
    it("Purchase", async () => {
      await testing.mintTatacuy(alice, [1, ++uuid]); // uuid 6 tatacuy
    });
  });

  describe("Wiracocha", () => {
    it("Purchase", async () => {
      await testing.mintWiracocha(alice, [1, ++uuid]); // uuid 7 wiracocha
    });
  });

  describe("Guinea Pig", () => {
    it("Purchase ", async () => {
      await pachaCuyToken.mint(alice.address, pe("50000"));
      await testing.purchaseGuineaPig(alice, [++uuid, 3]); // uuid 8 guinea pig
    });
  });
});
