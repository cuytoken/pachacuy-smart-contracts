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
    });

    xit("Provides tokens", async () => {
      await purchaseAssetController.connect(alice).purchaseGuineaPigWithPcuy(3); // uuid 1
      await randomNumberGenerator.fulfillRandomWords(
        432423,
        [2131432235423, 324325234146]
      );
      await purchaseAssetController.connect(alice).purchaseLandWithPcuy(100); // uuid 2

      var currUuid = 2;
      await nftProducerPachacuy.connect(alice).mintTatacuy(currUuid); // uuid 3
      await nftProducerPachacuy.connect(alice).mintWiracocha(currUuid); // uuid 4
      await nftProducerPachacuy.connect(alice).mintHatunWasi(currUuid); // uuid 5
      await purchaseAssetController.connect(alice).purchaseChakra(currUuid); // uuid 6
      await purchaseAssetController.connect(bob).purchaseFoodFromChakra(6);

      // Tatacuy
      var _pachaUuid = 2;
      var _tatacuyUuid = 3;
      var _totalFundsPcuyDeposited = pe("100000000000000000000");
      var _ratePcuyToSamiPoints = 20;
      var _totalFundsSamiPoints = pe("2000000000000000000000");
      var _prizePerWinnerSamiPoints = pe("20000000000000000000");
      await tatacuy
        .connect(alice)
        .startTatacuyCampaign(
          _pachaUuid,
          _tatacuyUuid,
          _totalFundsPcuyDeposited,
          _ratePcuyToSamiPoints,
          _totalFundsSamiPoints,
          _prizePerWinnerSamiPoints
        );

      // try luck
      var _account = bob.address;
      var _pachaOwner = alice.address;
      var _pachaUuid = 2;
      var _likelihood = 4;
      await tatacuy.grantRole(game_manager, owner.address);
      await tatacuy.tryMyLuckTatacuy(
        _account,
        _pachaOwner,
        _pachaUuid,
        _likelihood
      );

      await randomNumberGenerator.fulfillRandomWords(_account, [7]);

      // Wiracocha
      var _exchanger = bob.address;
      var _pachaOwner = alice.address;
      var _pachaUuid = 2;
      var _samiPoints = 500;
      var _amountPcuy = 100;
      var _rateSamiPointsToPcuy = 5;
      await wiracocha.grantRole(game_manager, owner.address);
      await wiracocha.exchangeSamiToPcuy(
        _exchanger,
        _pachaOwner,
        _pachaUuid,
        _samiPoints,
        _amountPcuy,
        _rateSamiPointsToPcuy
      );
    });
  });

  describe("Misay Wasi", () => {
    var pachaUuid;
    var misayWasiUuid;
    var campaignEndDate = async () =>
      (await ethers.provider.getBlock()).timestamp + 200;

    it("Alice receives tokens, gets guinea pig, land and misay wasi", async () => {
      // tokens
      await pachaCuyToken.mint(alice.address, pe("5725"));

      // guiena pig
      await purchaseAssetController.connect(alice).purchaseGuineaPigWithPcuy(3); // uuid 1
      await randomNumberGenerator.fulfillRandomWords(
        432423,
        [2131432235423, 324325234146]
      );
      console.log(
        "GP",
        (await pachaCuyToken.balanceOf(alice.address)).toString()
      );
      // land
      await purchaseAssetController.connect(alice).purchaseLandWithPcuy(1); // uuid 2
      console.log(
        "L",
        (await pachaCuyToken.balanceOf(alice.address)).toString()
      );

      // mint misay wasi
      pachaUuid = 2;
      await purchaseAssetController.connect(alice).purchaseMisayWasi(pachaUuid); // uuid 3
      console.log(
        "MWS",
        (await pachaCuyToken.balanceOf(alice.address)).toString()
      );

      misayWasiUuid = 3;
      await misayWasi.connect(alice).startMisayWasiRaffle(
        // uuid 5
        misayWasiUuid,
        pe("100"),
        pe("10"),
        campaignEndDate()
      );
      /** ALICE           UUID
       *  - guinea pig ->   1
       *  - land ->         2
       *  - misay wasi ->   3
       *  - misay wasi ticket ->   4
       *  - misay wai prize 100
       */
    });

    it("Bob, Carl & Deysi play at Alice's Miwasaysi", async () => {
      // tokens
      await pachaCuyToken.mint(bob.address, pe("500"));
      await pachaCuyToken.mint(carl.address, pe("500"));
      await pachaCuyToken.mint(deysi.address, pe("500"));

      var alicePrevBalance = await balanceOf(alice.address);
      var bobPrevBalance = await balanceOf(bob.address);
      var carlPrevBalance = await balanceOf(carl.address);
      var deysiPrevBalance = await balanceOf(deysi.address);

      console.log("alice Prev", alicePrevBalance);
      console.log("bob Prev", bobPrevBalance);
      console.log("carl Prev", carlPrevBalance);
      console.log("deysi Prev", deysiPrevBalance);

      // guinea pig
      await purchaseAssetController.connect(bob).purchaseGuineaPigWithPcuy(3); // uuid 5
      await randomNumberGenerator.fulfillRandomWords(
        432423,
        [2131432235423, 324325234146]
      );
      await purchaseAssetController.connect(carl).purchaseGuineaPigWithPcuy(3); // uuid 6
      await randomNumberGenerator.fulfillRandomWords(
        432423,
        [2131432235423, 324325234146]
      );
      await purchaseAssetController.connect(deysi).purchaseGuineaPigWithPcuy(3); // uuid 7
      await randomNumberGenerator.fulfillRandomWords(
        432423,
        [2131432235423, 324325234146]
      );

      // purchase ticket
      await purchaseAssetController
        .connect(carl)
        .purchaseTicketFromMisayWasi(misayWasiUuid, 1);
      console.log("1 Carl", await balanceOf(carl.address));
      console.log("1 alice", await balanceOf(alice.address));
      await purchaseAssetController
        .connect(bob)
        .purchaseTicketFromMisayWasi(misayWasiUuid, 1);
      console.log("2 bob", await balanceOf(bob.address));
      console.log("2 alice", await balanceOf(alice.address));
      await purchaseAssetController
        .connect(carl)
        .purchaseTicketFromMisayWasi(misayWasiUuid, 2);
      console.log("3 carl", await balanceOf(carl.address));
      console.log("3 alice", await balanceOf(alice.address));
      await purchaseAssetController
        .connect(deysi)
        .purchaseTicketFromMisayWasi(misayWasiUuid, 1);
      console.log("4 deysi", await balanceOf(deysi.address));
      console.log("4 alice", await balanceOf(alice.address));
      await purchaseAssetController
        .connect(carl)
        .purchaseTicketFromMisayWasi(misayWasiUuid, 1);
      console.log("5 carl", await balanceOf(carl.address));
      console.log("5 alice", await balanceOf(alice.address));

      await misayWasi.startRaffleContest([misayWasiUuid]);
      await randomNumberGenerator.fulfillRandomWords(432423, [2]);

      var aliceAfterBalance = await balanceOf(alice.address);
      var bobAfterBalance = await balanceOf(bob.address);
      var carlAfterBalance = await balanceOf(carl.address);
      var deysiAfterBalance = await balanceOf(deysi.address);

      console.log("alice AfterBalance", aliceAfterBalance);
      console.log("bob AfterBalance", bobAfterBalance);
      console.log("carl AfterBalance", carlAfterBalance);
      console.log("deysi AfterBalance", deysiAfterBalance);
    });
  });

  describe("Qhatu Wasi", () => {
    it("Bob purchases a Qhatuy Wasi", async () => {
      await pachaCuyToken.mint(bob.address, pe("5000"));
      await purchaseAssetController.connect(bob).purchaseLandWithPcuy(2); // uuid 8
      pachaUuid = 8;
      await purchaseAssetController.connect(bob).purchaseQhatuWasi(pachaUuid); // uuid 9
      //
      console.log("bobBal", await balanceOf(bob.address));
      var qhatuWasiUuid = 9;
      await qhatuWasi
        .connect(bob)
        .startQhatuWasiCampaign(qhatuWasiUuid, pe("40"));
      console.log("bobBal", await balanceOf(bob.address));
    });
  });
});
