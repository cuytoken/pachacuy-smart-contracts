const { expect } = require("chai");
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
} = require("../js-utils/helpers");
// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";

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
      // RandomNumberGenerator = await gcf("RandomNumberGenerator");
      RandomNumberGenerator = await gcf("RandomNumberV2Mock");
      // randomNumberGenerator = await dp(RandomNumberGenerator, [], {
      //   kind: "uups",
      // });
      randomNumberGenerator = await RandomNumberGenerator.deploy();
      await randomNumberGenerator.deployed();

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
        [
          randomNumberGenerator.address,
          process.env.WALLET_FOR_FUNDS,
          _busdToken,
        ],
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
    });
  });

  describe("Guinea Pigs", () => {
    it("Purchase", async () => {
      await pachaCuyToken.mint(alice.address, pe("50000"));
      await pachaCuyToken.mint(bob.address, pe("50000"));
      await pachaCuyToken.mint(carl.address, pe("50000"));
      await pachaCuyToken.mint(deysi.address, pe("50000"));
      await pachaCuyToken.mint(earl.address, pe("50000"));

      var pac = purchaseAssetController;
      var tx1 = await pac.connect(alice).purchaseGuineaPigWithPcuy(3);
      var tx2 = await pac.connect(bob).purchaseGuineaPigWithPcuy(3);
      var tx3 = await pac.connect(carl).purchaseGuineaPigWithPcuy(3);
      var tx4 = await pac.connect(deysi).purchaseGuineaPigWithPcuy(3);
      var tx5 = await pac.connect(earl).purchaseGuineaPigWithPcuy(3);

      var res1 = (await getDataFromEvent(tx1, "GPP")).toString();
      var res2 = (await getDataFromEvent(tx2, "GPP")).toString();
      var res3 = (await getDataFromEvent(tx3, "GPP")).toString();
      var res4 = (await getDataFromEvent(tx4, "GPP")).toString();
      var res5 = (await getDataFromEvent(tx5, "GPP")).toString();

      expect(res1).to.equal("1", "Incorrect Guinea Pig Uuid 1");
      expect(res2).to.equal("2", "Incorrect Guinea Pig Uuid 2");
      expect(res3).to.equal("3", "Incorrect Guinea Pig Uuid 3");
      expect(res4).to.equal("4", "Incorrect Guinea Pig Uuid 4");
      expect(res5).to.equal("5", "Incorrect Guinea Pig Uuid 5");

      await expect(tx1).to.emit(pac, "GuineaPigPurchaseFinish");
      await expect(tx2).to.emit(pac, "GuineaPigPurchaseFinish");
      await expect(tx3).to.emit(pac, "GuineaPigPurchaseFinish");
      await expect(tx4).to.emit(pac, "GuineaPigPurchaseFinish");
      await expect(tx5).to.emit(pac, "GuineaPigPurchaseFinish");
    });
  });

  describe("Pachas", () => {
    it("Purchase", async () => {
      var businesses = [
        "CHAKRA",
        "PACHA",
        "QHATU_WASI",
        "MISAY_WASI",
        "GUINEA_PIG_1",
        "GUINEA_PIG_2",
        "GUINEA_PIG_3",
      ];
      var PACHA = "PACHA";
      var pachaPrice = await pachacuyInfo.getPriceInPcuy(
        ethers.utils.toUtf8Bytes(PACHA)
      );
      var poolRewardAddress = await pachacuyInfo.poolRewardAddress();

      var pac = purchaseAssetController;
      var tx1 = await pac.connect(alice).purchaseLandWithPcuy(1);
      var tx2 = await pac.connect(bob).purchaseLandWithPcuy(2);
      var tx3 = await pac.connect(carl).purchaseLandWithPcuy(3);
      var tx4 = await pac.connect(deysi).purchaseLandWithPcuy(4);
      var tx5 = await pac.connect(earl).purchaseLandWithPcuy(5);
      var txs = [tx1, tx2, tx3, tx4, tx5];

      var res1 = (await getDataFromEvent(tx1, "PP")).toString();
      var res2 = (await getDataFromEvent(tx2, "PP")).toString();
      var res3 = (await getDataFromEvent(tx3, "PP")).toString();
      var res4 = (await getDataFromEvent(tx4, "PP")).toString();
      var res5 = (await getDataFromEvent(tx5, "PP")).toString();

      expect(res1).to.equal("6", "Incorrect Pacha Uuid 6");
      expect(res2).to.equal("7", "Incorrect Pacha Uuid 7");
      expect(res3).to.equal("8", "Incorrect Pacha Uuid 8");
      expect(res4).to.equal("9", "Incorrect Pacha Uuid 9");
      expect(res5).to.equal("10", "Incorrect Pacha Uuid 10");

      var pr = poolRewardAddress;
      var args1 = [alice.address, res1, pe(pachaPrice.toString()), 1, pr];
      var args2 = [bob.address, res2, pe(pachaPrice.toString()), 2, pr];
      var args3 = [carl.address, res3, pe(pachaPrice.toString()), 3, pr];
      var args4 = [deysi.address, res4, pe(pachaPrice.toString()), 4, pr];
      var args5 = [earl.address, res5, pe(pachaPrice.toString()), 5, pr];
      var addresses = [args1, args2, args3, args4, args5];
      var promises = addresses.map((args, ix) =>
        expect(txs[ix])
          .to.emit(pac, "PurchaseLand")
          .withArgs(...args)
      );
      await Promise.all(promises);
    });
  });

  describe("Chakra", () => {
    it("Purchase chakra", async () => {
      var pac = purchaseAssetController;
      var tx1 = await pac.connect(alice).purchaseChakra(6);
      var tx2 = await pac.connect(bob).purchaseChakra(7);
      var tx3 = await pac.connect(carl).purchaseChakra(8);
      var tx4 = await pac.connect(deysi).purchaseChakra(9);
      var tx5 = await pac.connect(earl).purchaseChakra(10);
      var txs = [tx1, tx2, tx3, tx4, tx5];

      var res1 = (await getDataFromEvent(tx1, "CHKR")).toString();
      var res2 = (await getDataFromEvent(tx2, "CHKR")).toString();
      var res3 = (await getDataFromEvent(tx3, "CHKR")).toString();
      var res4 = (await getDataFromEvent(tx4, "CHKR")).toString();
      var res5 = (await getDataFromEvent(tx5, "CHKR")).toString();

      expect(res1).to.equal("11", "Incorrect Chakra Uuid 11");
      expect(res2).to.equal("12", "Incorrect Chakra Uuid 12");
      expect(res3).to.equal("13", "Incorrect Chakra Uuid 13");
      expect(res4).to.equal("14", "Incorrect Chakra Uuid 14");
      expect(res5).to.equal("15", "Incorrect Chakra Uuid 15");
    });

    it("Set up food price", async () => {
      var p1 = pe("15");
      var p2 = pe("25");
      var p3 = pe("35");
      var p4 = pe("45");
      var p5 = pe("55");
      var tx1 = await chakra.connect(alice).updateFoodPriceAtChakra(11, p1);
      var tx2 = await chakra.connect(bob).updateFoodPriceAtChakra(12, p2);
      var tx3 = await chakra.connect(carl).updateFoodPriceAtChakra(13, p3);
      var tx4 = await chakra.connect(deysi).updateFoodPriceAtChakra(14, p4);
      var tx5 = await chakra.connect(earl).updateFoodPriceAtChakra(15, p5);
      var txs = [tx1, tx2, tx3, tx4, tx5];
    });

    it("Purchase food", async () => {
      var pac = purchaseAssetController;
      await pachaCuyToken.mint(fephe.address, pe("50000"));
      await pachaCuyToken.mint(gary.address, pe("50000"));
      await pachaCuyToken.mint(huidobro.address, pe("50000"));

      var tx1 = await pac.connect(fephe).purchaseGuineaPigWithPcuy(3); // 16
      var tx2 = await pac.connect(gary).purchaseGuineaPigWithPcuy(3); // 17
      var tx3 = await pac.connect(huidobro).purchaseGuineaPigWithPcuy(3); // 18

      var res1 = (await getDataFromEvent(tx1, "GPP")).toString();
      var res2 = (await getDataFromEvent(tx2, "GPP")).toString();
      var res3 = (await getDataFromEvent(tx3, "GPP")).toString();

      var tx1 = await pac.connect(fephe).purchaseFoodFromChakra(11, 1, res1);
      var tx2 = await pac.connect(gary).purchaseFoodFromChakra(12, 2, res2);
      var tx3 = await pac.connect(huidobro).purchaseFoodFromChakra(13, 2, res3);
      var tx1 = await pac.connect(fephe).purchaseFoodFromChakra(13, 3, res1);
      var tx2 = await pac.connect(gary).purchaseFoodFromChakra(14, 4, res2);
      var tx3 = await pac.connect(huidobro).purchaseFoodFromChakra(15, 5, res3);
    });
  });

  describe("Misay Wasi", () => {
    var campaignEndDate = async () =>
      (await ethers.provider.getBlock()).timestamp + 200;

    it("Purchase Misaywasi", async () => {
      // mint misay wasi
      var pac = purchaseAssetController;
      var tx1 = await pac.connect(alice).purchaseMisayWasi(6);
      var tx2 = await pac.connect(bob).purchaseMisayWasi(7);
      var tx3 = await pac.connect(carl).purchaseMisayWasi(8);
      var tx4 = await pac.connect(deysi).purchaseMisayWasi(9);
      var tx5 = await pac.connect(earl).purchaseMisayWasi(10);
      var txs = [tx1, tx2, tx3, tx4, tx5];

      var res1 = (await getDataFromEvent(tx1, "MSWS")).toString();
      var res2 = (await getDataFromEvent(tx2, "MSWS")).toString();
      var res3 = (await getDataFromEvent(tx3, "MSWS")).toString();
      var res4 = (await getDataFromEvent(tx4, "MSWS")).toString();
      var res5 = (await getDataFromEvent(tx5, "MSWS")).toString();

      expect(res1).to.equal("19", "Incorrect MSWS Uuid 16");
      expect(res2).to.equal("20", "Incorrect MSWS Uuid 17");
      expect(res3).to.equal("21", "Incorrect MSWS Uuid 18");
      expect(res4).to.equal("22", "Incorrect MSWS Uuid 19");
      expect(res5).to.equal("23", "Incorrect MSWS Uuid 20");
    });

    it("Alice starts raffle", async () => {
      var mswsUuid = 19;
      var prize = pe("100");
      await misayWasi
        .connect(alice)
        .startMisayWasiRaffle(mswsUuid, prize, pe("10"), campaignEndDate()); // uuid 24
    });

    it("Purchase Alice's raffle", async () => {
      var mswsUuid = 19;
      var pac = purchaseAssetController;
      var buyers = [bob, carl, earl, deysi];
      var promises = buyers.map((buyer, ix) =>
        pac.connect(buyer).purchaseTicketFromMisayWasi(mswsUuid, ix + 1)
      );
      await Promise.all(promises);
    });

    it("Starts raffle", async () => {
      var mswsUuid = 19;
      await misayWasi.grantRole(game_manager, owner.address);
      await misayWasi.connect(owner).startRaffleContest([mswsUuid]);
      var buyers = [bob, carl, earl, deysi];
      var accumulative = [1, 3, 6, 10];
      var tickets = accumulative[accumulative.length - 1];
      var rn = 123;
      var finalRn = (rn % tickets) + 1; // 4
      var ixWinner = 3;
      var winner = buyers[ixWinner - 1].address;
      var tx = await randomNumberGenerator.fulfillRandomWords(1234324, [rn]);
      var prize = pe("100");
      var tMsws = 24;
      var tax = await pachacuyInfo.raffleTax();
      var fee = prize.mul(tax).div(100);
      var net = prize.sub(fee);
      var args = [winner, mswsUuid, net, fee, tMsws];
      await expect(tx)
        .to.emit(misayWasi, "RaffleContestFinished")
        .withArgs(...args);
    });
  });

  describe("Qhatu Wasi", () => {
    it("Purchase", async () => {
      var pac = purchaseAssetController;
      var tx1 = await pac.connect(alice).purchaseQhatuWasi(6);
      var tx2 = await pac.connect(bob).purchaseQhatuWasi(7);
      var tx3 = await pac.connect(carl).purchaseQhatuWasi(8);
      var tx4 = await pac.connect(deysi).purchaseQhatuWasi(9);
      var tx5 = await pac.connect(earl).purchaseQhatuWasi(10);
      var txs = [tx1, tx2, tx3, tx4, tx5];

      var res1 = (await getDataFromEvent(tx1, "CHKR")).toString();
      var res2 = (await getDataFromEvent(tx2, "CHKR")).toString();
      var res3 = (await getDataFromEvent(tx3, "CHKR")).toString();
      var res4 = (await getDataFromEvent(tx4, "CHKR")).toString();
      var res5 = (await getDataFromEvent(tx5, "CHKR")).toString();

      expect(res1).to.equal("25", "Incorrect QhatuWasi Uuid 25");
      expect(res2).to.equal("26", "Incorrect QhatuWasi Uuid 26");
      expect(res3).to.equal("27", "Incorrect QhatuWasi Uuid 27");
      expect(res4).to.equal("28", "Incorrect QhatuWasi Uuid 28");
      expect(res5).to.equal("29", "Incorrect QhatuWasi Uuid 29");
    });

    it("Alice starts campaign", async () => {
      var qhatuWasiUuid = 25;
      var qtTax = await pachacuyInfo.qhatuWasiTax();
      var qt = qhatuWasi;
      var amountCmp = pe("40");
      var prizePerView = pe("4");
      var sami = await pachacuyInfo.convertPcuyToSami(prizePerView);
      var tax = amountCmp.mul(qtTax).div(100);
      var net = amountCmp.sub(tax);
      var samiGive = await pachacuyInfo.convertPcuyToSami(net);
      var tx = await qhatuWasi
        .connect(alice)
        .startQhatuWasiCampaign(qhatuWasiUuid, amountCmp, prizePerView);
      var args = [tax, net, samiGive, qhatuWasiUuid, alice.address, sami];
      expect(tx)
        .to.emit(qt, "QhatuWasiCampaignStarted")
        .withArgs(...args);
    });
  });

  describe("Pachapass", () => {
    it("Set Pacha to private - type 1", async () => {
      var pachaUuid = 6;
      var price = pe("0");
      await pacha
        .connect(alice)
        .setPachaPrivacyAndDistribution(pachaUuid, price, 1);
    });

    it("Distribute - type 1", async () => {
      var pachaUuid = 6;
      var accounts = [earl, fephe, gary, huidobro].map((el) => el.address);
      await nftProducerPachacuy
        .connect(alice)
        .mintPachaPassAsOwner(accounts, pachaUuid);
    });

    it("Set Pacha to private - type 2", async () => {
      var pachaUuid = 7;
      var price = pe("10");
      await pacha
        .connect(bob)
        .setPachaPrivacyAndDistribution(pachaUuid, price, 2);
    });

    it("Purchase type 2", async () => {
      var pac = purchaseAssetController;
      var pachaUuid = 7;
      var tx1 = await pac.connect(fephe).purchasePachaPass(pachaUuid);
      var tx2 = await pac.connect(gary).purchasePachaPass(pachaUuid);
      var tx3 = await pac.connect(huidobro).purchasePachaPass(pachaUuid);

      var res1 = (await getDataFromEvent(tx1, "PCHPSS")).toString();
      var res2 = (await getDataFromEvent(tx2, "PCHPSS")).toString();
      var res3 = (await getDataFromEvent(tx3, "PCHPSS")).toString();

      expect(res1).to.equal("31", "Incorrect Pacha Pass Uuid 31");
      expect(res2).to.equal("31", "Incorrect Pacha Pass Uuid 31");
      expect(res3).to.equal("31", "Incorrect Pacha Pass Uuid 31");
    });
  });

  describe("URI", () => {
    xit("Reading uri", async () => {
      console.log("1", await nftProducerPachacuy.tokenURI(1));
      console.log("2", await nftProducerPachacuy.tokenURI(2));
      console.log("3", await nftProducerPachacuy.tokenURI(3));
      console.log("4", await nftProducerPachacuy.tokenURI(4));
      console.log("5", await nftProducerPachacuy.tokenURI(5));
      console.log("6", await nftProducerPachacuy.tokenURI(6));
      console.log("7", await nftProducerPachacuy.tokenURI(7));
      console.log("8", await nftProducerPachacuy.tokenURI(8));
      console.log("9", await nftProducerPachacuy.tokenURI(9));
    });
  });
});
