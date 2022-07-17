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
} = require("../js-utils/helpers");
const { init } = require("../js-utils/helpterTesting");
// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";
var _prefix = "ipfs://QmbbGgo93M6yr5WSUMj53SWN2vC7L6aMS1GZSPNkVRY8e4/";
var testing;
var cw = process.env.WALLET_FOR_FUNDS;

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
       * nftP 005 - grant game_role to Pacha
       * nftP 006 - Inlcude all smart contracts for burning
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

      // init helper
      testing = init(
        purchaseAssetController,
        pachaCuyToken,
        pachacuyInfo,
        chakra,
        pachacuyInfo,
        guineaPig,
        misayWasi,
        randomNumberGenerator
      );
    });
  });

  describe("Guinea Pigs", () => {
    it("Empty list guinea pigs", async () => {
      var res = await guineaPig.getListOfGuineaPigs();
      expect(res.length).to.equal(0);
    });

    it("Purchase", async () => {
      await pachaCuyToken.mint(alice.address, pe("50000"));
      await pachaCuyToken.mint(bob.address, pe("50000"));
      await pachaCuyToken.mint(carl.address, pe("50000"));
      await pachaCuyToken.mint(deysi.address, pe("50000"));
      await pachaCuyToken.mint(earl.address, pe("50000"));
      await testing.purchaseGuineaPig(alice, [++uuid, 3]); // uuid 1 guinea pig
      await testing.purchaseGuineaPig(bob, [++uuid, 3]); // uuid 2 guinea pig
      await testing.purchaseGuineaPig(carl, [++uuid, 3]); // uuid 3 guinea pig
      await testing.purchaseGuineaPig(deysi, [++uuid, 3]); // uuid 4 guinea pig
      await testing.purchaseGuineaPig(earl, [++uuid, 3]); // uuid 5 guinea pig
    });

    it("Correct # of guinea pigs", async () => {
      var res = await guineaPig.getListOfGuineaPigs();
      expect(res.length).to.equal(5);
    });
  });

  describe("Pachas", () => {
    it("Purchase with no funds", async () => {
      var pac = purchaseAssetController;
      await expect(
        pac.connect(huidobro).purchaseLandWithPcuy(1)
      ).to.revertedWith("PAC: Not enough PCUY");
    });

    it("Purchase 5 pachas 6-10", async () => {
      await testing.purchaseLand(alice, [1, ++uuid]); // uuid 6 pacha
      await testing.purchaseLand(bob, [2, ++uuid]); // uuid 7 pacha
      await testing.purchaseLand(carl, [3, ++uuid]); // uuid 8 pacha
      await testing.purchaseLand(deysi, [4, ++uuid]); // uuid 9 pacha
      await testing.purchaseLand(earl, [5, ++uuid]); // uuid 10 pacha
    });

    it("Purchase same location", async () => {
      var pac = purchaseAssetController;
      await expect(pac.connect(bob).purchaseLandWithPcuy(1)).to.revertedWith(
        "NFP: location taken"
      );
    });

    it("Location out of bounds", async () => {
      var pac = purchaseAssetController;
      await expect(pac.connect(bob).purchaseLandWithPcuy(0)).to.revertedWith(
        "Pacha: Out of bounds"
      );
      await expect(pac.connect(bob).purchaseLandWithPcuy(698)).to.revertedWith(
        "Pacha: Out of bounds"
      );
    });

    it("Check correct URI", async () => {
      var locations = [1, 2, 3, 4, 5];
      var uuids = [6, 7, 8, 9, 10];
      var uris = locations.map((location) => `${_prefix}PACHA${location}.json`);
      var promises = uuids.map((uuid) => nftProducerPachacuy.tokenURI(uuid));
      var tokenUris = await Promise.all(promises);
      tokenUris.forEach((tokenUri, ix) =>
        expect(tokenUri).to.equal(uris[ix], `Failed at ${ix}`)
      );
    });
  });

  describe("Chakra", () => {
    it("Purchase with no funds", async () => {
      var pac = purchaseAssetController;
      await pachaCuyToken.mint(huidobro.address, pe("5000"));
      ++uuid;
      await pac.connect(huidobro).purchaseLandWithPcuy(6); // uuid 11
      await expect(pac.connect(huidobro).purchaseChakra(1)).to.revertedWith(
        "PAC: Not enough PCUY"
      );
    });

    it("Verify wrong pacha's uuid", async () => {
      var pac = purchaseAssetController;
      await expect(pac.connect(alice).purchaseChakra(999)).to.revertedWith(
        "NFP: No pacha found"
      );
    });

    it("Purchase chakra", async () => {
      await testing.purchaseChakra(alice, [6, ++uuid]); //  uuid 12 chakra
      await testing.purchaseChakra(bob, [7, ++uuid]); // uuid 13 chakra
      await testing.purchaseChakra(carl, [8, ++uuid]); // uuid 14 chakra
      await testing.purchaseChakra(deysi, [9, ++uuid]); // uuid 15 chakra
      await testing.purchaseChakra(earl, [10, ++uuid]); // uuid 16 chakra
    });

    it("Amount of available chakras", async () => {
      var amountOfChakras = [alice, bob, carl, deysi, earl].length;
      var res = await chakra.getListOfChakrasWithFood();
      expect(res.length).to.equal(amountOfChakras);
    });

    it("Set up & check food price", async () => {
      var prices = [pe("16"), pe("25"), pe("35"), pe("45"), pe("55")];
      var uuids = [12, 13, 14, 15, 16];
      var buyers = [alice, bob, carl, deysi, earl];
      var promises = buyers.map((buyer, ix) =>
        chakra.connect(buyer).updateFoodPriceAtChakra(uuids[ix], prices[ix])
      );
      await Promise.all(promises);
      var results = await chakra.getListOfChakrasWithFood();
      var compare = buyers.map((buyer, ix) => ({
        owner: buyer.address,
        pricePerFood: prices[ix],
        chakraUuid: uuids[ix],
      }));
      results.forEach((result, ix) => {
        expect(result.owner).to.equal(compare[ix].owner);
        expect(result.pricePerFood).to.equal(compare[ix].pricePerFood);
        expect(result.chakraUuid).to.equal(compare[ix].chakraUuid);
      });
    });

    it("Purchase food wrong chakra", async () => {
      var pac = purchaseAssetController;
      // chakras uuids = 12,13,14,15,16
      await pachaCuyToken.mint(fephe.address, pe("50000"));
      await pachaCuyToken.mint(gary.address, pe("50000"));
      await pachaCuyToken.mint(huidobro.address, pe("375"));

      await testing.purchaseGuineaPig(fephe, [++uuid, 1]); // uuid 17 guinea pig
      await testing.purchaseGuineaPig(gary, [++uuid, 2]); // uuid 18 guinea pig
      await testing.purchaseGuineaPig(huidobro, [++uuid, 3]); // uuid 19 guinea pig

      await expect(
        pac.connect(fephe).purchaseFoodFromChakra(11, 4, 17)
      ).to.revertedWith("PAC: Chakra not found");
    });

    it("Purchase food no funds", async () => {
      var pac = purchaseAssetController;
      await expect(
        pac.connect(huidobro).purchaseFoodFromChakra(12, 4, 19)
      ).to.revertedWith("PAC: Not enough PCUY");
    });

    it("Purchase food wrong guinea pig", async () => {
      var pac = purchaseAssetController;
      await expect(
        pac.connect(fephe).purchaseFoodFromChakra(12, 4, 4)
      ).to.revertedWith("NFP: No guinea pig found");
    });

    it("Purchase food", async () => {
      var pac = purchaseAssetController;

      var chakraUuid = 12;
      var results = await chakra.getListOfChakrasWithFood();
      results = results.filter((result) => result.chakraUuid == chakraUuid);
      expect(results.length).to.equal(1);
      //            purchaseFood([chakraUuid, amountFood, guineaPigUuid])
      await testing.purchaseFood(fephe, [chakraUuid, 2, 17]);
      await testing.purchaseFood(fephe, [chakraUuid, 2, 17]);
      await testing.purchaseFood(fephe, [chakraUuid, 4, 17]);
      await testing.purchaseFood(fephe, [chakraUuid, 4, 17]);

      var results = await chakra.getListOfChakrasWithFood();
      results = results.filter((result) => result.chakraUuid == chakraUuid);
      expect(results.length).to.equal(0);
    });

    it("Purchase food - empty chakra", async () => {
      var pac = purchaseAssetController;
      await expect(
        pac.connect(fephe).purchaseFoodFromChakra(12, 2, 17)
      ).to.revertedWith("PAC: Not enough food at chakra");
    });

    it("Burn chakra", async () => {
      // alice ->  uuid 12 chakra
      // bob -> uuid 13 chakra
      // carl -> uuid 14 chakra
      // deysi -> uuid 15 chakra
      // earl, -> uuid 16 chakra
      var aUuid = 12;
      var bUuid = 13;
      var cUuid = 14;
      var dUuid = 15;
      var eUuid = 16;

      // balances at NFT Producer
      var bal = await nftProducerPachacuy.balanceOf(alice.address, aUuid);
      expect(bal.toString()).to.equal(String(1));
      var bal = await nftProducerPachacuy.balanceOf(bob.address, bUuid);
      expect(bal.toString()).to.equal(String(1));
      var bal = await nftProducerPachacuy.balanceOf(carl.address, cUuid);
      expect(bal.toString()).to.equal(String(1));
      var bal = await nftProducerPachacuy.balanceOf(deysi.address, dUuid);
      expect(bal.toString()).to.equal(String(1));
      var bal = await nftProducerPachacuy.balanceOf(earl.address, eUuid);
      expect(bal.toString()).to.equal(String(1));

      var beforeQ = await chakra.getListOfChakrasWithFood();
      await chakra.connect(deysi).burnChakra(15);
      await chakra.connect(earl).burnChakra(16);
      var afterQ = await chakra.getListOfChakrasWithFood();
      expect(beforeQ.length - 2).to.equal(afterQ.length);

      var [owner] = await chakra.getChakraWithUuid(12);
      expect(owner).to.equal(alice.address);
      var [owner] = await chakra.getChakraWithUuid(13);
      expect(owner).to.equal(bob.address);
      var [owner] = await chakra.getChakraWithUuid(14);
      expect(owner).to.equal(carl.address);
      var [owner] = await chakra.getChakraWithUuid(15);
      expect(owner).to.equal("0x0000000000000000000000000000000000000000");
      var [owner] = await chakra.getChakraWithUuid(16);
      expect(owner).to.equal("0x0000000000000000000000000000000000000000");

      // balances at NFT Producer
      var bal = await nftProducerPachacuy.balanceOf(alice.address, aUuid);
      expect(bal.toString()).to.equal(String(1));
      var bal = await nftProducerPachacuy.balanceOf(bob.address, bUuid);
      expect(bal.toString()).to.equal(String(1));
      var bal = await nftProducerPachacuy.balanceOf(carl.address, cUuid);
      expect(bal.toString()).to.equal(String(1));
      var bal = await nftProducerPachacuy.balanceOf(deysi.address, dUuid);
      expect(bal.toString()).to.equal(String(0));
      var bal = await nftProducerPachacuy.balanceOf(earl.address, eUuid);
      expect(bal.toString()).to.equal(String(0));
    });
  });

  describe("Misay Wasi", () => {
    var timestamp = async () => (await ethers.provider.getBlock()).timestamp;
    var campaignEndDate = async () =>
      (await ethers.provider.getBlock()).timestamp + 200;

    it("Purchase Misaywasi", async () => {
      // mint misay wasi
      await testing.purchaseMisaywasi(alice, [++uuid, 6]); // uuid misaywasi 20
      await testing.purchaseMisaywasi(bob, [++uuid, 7]); // uuid misaywasi 21
      await testing.purchaseMisaywasi(carl, [++uuid, 8]); // uuid misaywasi 22
      await testing.purchaseMisaywasi(deysi, [++uuid, 9]); // uuid misaywasi 23
      await testing.purchaseMisaywasi(earl, [++uuid, 10]); // uuid misaywasi 24
    });

    it("Raffle ticket price != 0", async () => {
      var mswsUuid = 20;
      var prize = pe("5");
      var endDate = await campaignEndDate();
      await expect(
        misayWasi
          .connect(alice)
          .startMisayWasiRaffle(mswsUuid, prize, 0, endDate)
      ).to.revertedWith("Misay Wasi: Zero price");
    });

    it("No raffle active", async () => {
      var res = await misayWasi.getListOfActiveMWRaffles();
      expect(res.length).to.equal(0);
    });

    it("Incorrect owner", async () => {
      var mswsUuid = 21;
      var prize = pe("500");
      var startDate = await timestamp();
      var endDate = await campaignEndDate();
      var tPrice = pe("50");

      await expect(
        misayWasi
          .connect(alice)
          .startMisayWasiRaffle(mswsUuid, prize, tPrice, endDate)
      ).to.revertedWith("Misay Wasi: Not the owner");
    });

    it("Purchase ticket - no raffle", async () => {
      var mswsUuid = 20;
      var pac = purchaseAssetController;
      await expect(
        pac.connect(bob).purchaseTicketFromMisayWasi(mswsUuid, 1)
      ).to.revertedWith("PAC: No raffle running");
    });

    it("Starts raffle", async () => {
      var mswsUuid = 20;
      var pachaUuid = 6;
      var prize = pe("100");
      var startDate = await timestamp();
      var endDate = startDate + 200;
      var tPrice = pe("10");

      await testing.startMisayWasiRaffle(alice, [
        mswsUuid,
        prize,
        tPrice,
        endDate,
        startDate,
        pachaUuid,
      ]); // uuid 25 ticket
      ++uuid;

      var mswsUuid = 21;
      var pachaUuid = 7;
      var prize = pe("500");
      var startDate = await timestamp();
      var endDate = await campaignEndDate();
      var tPrice = pe("50");
      await testing.startMisayWasiRaffle(bob, [
        mswsUuid,
        prize,
        tPrice,
        endDate,
        startDate,
        pachaUuid,
      ]); // uuid 26 ticket
      ++uuid;
    });

    it("Raffle count", async () => {
      var results = await misayWasi.getListOfActiveMWRaffles();
      results = results.filter(
        (res) => res.misayWasiUuid == 20 || res.misayWasiUuid == 21
      );
      expect(results.length).to.equal(2);
    });

    it("Can't start raffle twice", async () => {
      var mswsUuid = 21;
      var pachaUuid = 7;
      var prize = pe("500");
      var startDate = await timestamp();
      var endDate = await campaignEndDate();
      var tPrice = pe("5");

      await expect(
        misayWasi
          .connect(bob)
          .startMisayWasiRaffle(mswsUuid, prize, tPrice, endDate)
      ).to.revertedWith("Misay Wasi: Campaign is active");
    });

    it("Purchase Alice's raffle", async () => {
      var mswsUuid = 20;
      var tPr = pe("10");
      var buyers = [bob, carl, earl, deysi];
      var tickets = [3, 10, 50, 100];
      var t = 25; // ticket uuid of this msws
      // purchaseTicket(bob, [mswsUuid, amountTickets])
      var d = deysi;
      await testing.purchaseTicket(bob, [alice, mswsUuid, tPr, tickets[0], t]);
      await testing.purchaseTicket(carl, [alice, mswsUuid, tPr, tickets[1], t]);
      await testing.purchaseTicket(earl, [alice, mswsUuid, tPr, tickets[2], t]);
      await testing.purchaseTicket(d, [alice, mswsUuid, tPr, tickets[3], t]);
    });

    it("Starts raffle", async () => {
      // prev balance
      var prevBalAcc = await pachaCuyToken.balanceOf(deysi.address);
      var prevBalCustodianW = await pachaCuyToken.balanceOf(cw);

      var mswsUuid = 20;
      await misayWasi.grantRole(game_manager, owner.address);
      await misayWasi.connect(owner).startRaffleContest([mswsUuid]);
      var buyers = [bob, carl, earl, deysi];
      // var tickets = [3, 10, 50, 100];
      var accumulative = [3, 13, 63, 163];
      var tickets = accumulative[accumulative.length - 1];
      var rn = 123;
      var finalRn = (rn % tickets) + 1; // 124
      var ixWinner = 4;
      var winner = buyers[ixWinner - 1].address;
      var tx = await randomNumberGenerator.fulfillRandomWords(1234324, [rn]);
      var prize = pe("100");
      var tMsws = 25;
      var tax = await pachacuyInfo.raffleTax();
      var fee = prize.mul(tax).div(100);
      var net = prize.sub(fee);
      var args = [winner, mswsUuid, net, fee, tMsws];
      await expect(tx)
        .to.emit(misayWasi, "RaffleContestFinished")
        .withArgs(...args);

      var afterBalAcc = await pachaCuyToken.balanceOf(deysi.address);
      var afterBalCustodianW = await pachaCuyToken.balanceOf(cw);

      // check balance winner
      expect(afterBalAcc.sub(prevBalAcc).toString()).to.equal(net.toString());
      // check if custodian wallet received funds
      expect(prevBalCustodianW.sub(afterBalCustodianW).toString()).to.equal(
        prize.sub(fee).toString(),
        "Incorrect price custodian"
      );

      var misayWasiUuids = [mswsUuid, mswsUuid, mswsUuid];
      var promises = misayWasiUuids.map((mswsUuid) =>
        misayWasi.getHistoricWinners(mswsUuid)
      );
    });

    it("Active raffles list", async () => {
      var results = await misayWasi.getListOfActiveMWRaffles();
      results = results.filter(
        (res) => res.misayWasiUuid == 20 || res.misayWasiUuid == 21
      );
      expect(results.length).to.equal(1);
    });
  });

  describe("Qhatu Wasi", () => {
    it("Purchase with no funds", async () => {
      var pac = purchaseAssetController;
      await expect(pac.connect(huidobro).purchaseQhatuWasi(11)).to.revertedWith(
        "PAC: Not enough PCUY"
      );
    });

    it("Purchase", async () => {
      // testing.purchaseQhatuWasi(signer, [pachaUuid])
      await testing.purchaseQhatuWasi(alice, [6, ++uuid]); // uuid 27 qhatu wasi
      await testing.purchaseQhatuWasi(bob, [7, ++uuid]); // uuid 28 qhatu wasi
      await testing.purchaseQhatuWasi(carl, [8, ++uuid]); // uuid 29 qhatu wasi
      await testing.purchaseQhatuWasi(deysi, [9, ++uuid]); // uuid 30 qhatu wasi
      await testing.purchaseQhatuWasi(earl, [10, ++uuid]); // uuid 31 qhatu wasi
    });

    it("Alice starts campaign", async () => {
      // prev balance
      var prevBalAcc = await pachaCuyToken.balanceOf(alice.address);
      var prevBalCustodianW = await pachaCuyToken.balanceOf(cw);

      var qhatuWasiUuid = 27;
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

      // after balance
      var afterBalAcc = await pachaCuyToken.balanceOf(alice.address);
      var afterBalCustodianW = await pachaCuyToken.balanceOf(cw);

      // check balance account
      expect(prevBalAcc.sub(afterBalAcc).toString()).to.equal(
        amountCmp.toString()
      );
      // check if custodian wallet received funds
      expect(afterBalCustodianW.sub(prevBalCustodianW).toString()).to.equal(
        amountCmp.toString(),
        "Incorrect price custodian"
      );
    });
  });

  describe("Pachapass", () => {
    it("Set Pacha to private incorrect dist.", async () => {
      var pachaUuid = 6;
      var price = pe("0");
      await expect(
        pacha.connect(alice).setPachaPrivacyAndDistribution(pachaUuid, price, 0)
      ).to.be.revertedWith("Pacha: not 1 neither 2");
    });

    it("Set Pacha to private random uuid", async () => {
      var pachaUuid = 5;
      var price = pe("0");
      await expect(
        pacha.connect(bob).setPachaPrivacyAndDistribution(pachaUuid, price, 1)
      ).to.be.revertedWith("Pacha: Non-existant uuid");
    });

    it("Set Pacha to private not the owner ", async () => {
      var pachaUuid = 6;
      var price = pe("0");
      await expect(
        pacha.connect(bob).setPachaPrivacyAndDistribution(pachaUuid, price, 1)
      ).to.be.revertedWith("Pacha: not the owner");
    });

    it("Set Pacha to private - type 1", async () => {
      var pachaUuid = 6;
      var price = pe("0");
      await pacha
        .connect(alice)
        .setPachaPrivacyAndDistribution(pachaUuid, price, 1); // uuid 32 pacha pass
      ++uuid;

      var {
        isPacha,
        isPublic,
        uuid,
        pachaPassUuid,
        typeOfDistribution,
        owner,
        listPachaPassOwners,
      } = await pacha.getPachaWithUuid(pachaUuid);

      expect(isPacha).to.be.true;
      expect(isPublic).to.be.false;
      expect(uuid.toString()).to.equal(String(pachaUuid));
      expect(typeOfDistribution.toString()).to.equal(String(1));
      expect(owner).to.equal(alice.address);
      expect(listPachaPassOwners.length).to.equal(0);
    });

    it("Distribute - type 1", async () => {
      var pachaUuid = 6;
      var pachaPassUuid = 32;
      var accounts = [earl, fephe, gary, huidobro];
      var addresses = accounts.map((el) => el.address);
      await nftProducerPachacuy
        .connect(alice)
        .mintPachaPassAsOwner(addresses, pachaUuid);

      // pacha
      var { listPachaPassOwners } = await pacha.getPachaWithUuid(pachaUuid);
      expect(listPachaPassOwners.length).to.equal(accounts.length);
      addresses.forEach((address) => {
        var arr = listPachaPassOwners.filter((add) => add == address);
        expect(arr.length).to.equal(1);
      });

      // pacha pass
      var {
        isPachaPass,
        pachaUuid,
        typeOfDistribution,
        uuid,
        price,
        transferMode,
        listPachaPassOwners,
      } = await pacha.getPachaPassWithUuid(pachaPassUuid);
      expect(isPachaPass).to.be.true;
      expect(pachaUuid.toString()).to.equal(String(pachaUuid));
      expect(typeOfDistribution.toString()).to.equal(String(1));
      expect(uuid.toString()).to.equal(String(pachaPassUuid));
      expect(price).to.equal(pe("0"));
      expect(transferMode).to.equal("transferred");
      expect(listPachaPassOwners.length).to.equal(accounts.length);
      addresses.forEach((address) => {
        var arr = listPachaPassOwners.filter((add) => add == address);
        expect(arr.length).to.equal(1);
      });

      // receivers have pacha pass uuid balance
      var promises = addresses.map((address) =>
        nftProducerPachacuy.balanceOf(address, pachaPassUuid)
      );
      var results = await Promise.all(promises);
      results.forEach((result) =>
        expect(result.toString()).to.equal(String(1))
      );
    });

    it("Set Pacha to private - type 2", async () => {
      var pachaUuid = 7;
      var price = pe("10");
      await pacha
        .connect(bob)
        .setPachaPrivacyAndDistribution(pachaUuid, price, 2); // uuid 33 pacha pass
      ++uuid;
      var {
        isPacha,
        isPublic,
        uuid,
        pachaPassUuid,
        typeOfDistribution,
        owner,
        pachaPassPrice,
        listPachaPassOwners,
      } = await pacha.getPachaWithUuid(pachaUuid);

      expect(isPacha).to.be.true;
      expect(isPublic).to.be.false;
      expect(uuid.toString()).to.equal(String(pachaUuid));
      expect(pachaPassPrice).to.equal(String(price));
      expect(typeOfDistribution.toString()).to.equal(String(2));
      expect(owner).to.equal(bob.address);
      expect(listPachaPassOwners.length).to.equal(0);
    });

    it("Purchase type 2", async () => {
      var pPass = pe("10");
      await pachaCuyToken.mint(huidobro.address, pPass);

      var pUuid = 7; // pacha uuid
      var pcpsUuid = 33; // pacha pass uuid
      var own = bob.address;
      await testing.purchasePachaPass(fephe, [pUuid, pcpsUuid, pPass, own]);
      await testing.purchasePachaPass(gary, [pUuid, pcpsUuid, pPass, own]);
      await testing.purchasePachaPass(huidobro, [pUuid, pcpsUuid, pPass, own]);
    });

    it("Receivers have pacha pass", async () => {
      var pachaUuid = 7;
      var pachaPassUuid = 33;
      var accounts = [fephe, gary, huidobro];
      var addresses = accounts.map((el) => el.address);

      // pacha
      var { listPachaPassOwners } = await pacha.getPachaWithUuid(pachaUuid);
      expect(listPachaPassOwners.length).to.equal(accounts.length);
      addresses.forEach((address) => {
        var arr = listPachaPassOwners.filter((add) => add == address);
        expect(arr.length).to.equal(1);
      });

      // pacha pass
      var {
        isPachaPass,
        pachaUuid,
        typeOfDistribution,
        uuid,
        price,
        transferMode,
        listPachaPassOwners,
      } = await pacha.getPachaPassWithUuid(pachaPassUuid);
      expect(isPachaPass).to.be.true;
      expect(pachaUuid.toString()).to.equal(String(pachaUuid));
      expect(typeOfDistribution.toString()).to.equal(String(2));
      expect(uuid.toString()).to.equal(String(pachaPassUuid));
      expect(price).to.equal(pe("10"));
      expect(transferMode).to.equal("purchased");
      expect(listPachaPassOwners.length).to.equal(accounts.length);
      addresses.forEach((address) => {
        var arr = listPachaPassOwners.filter((add) => add == address);
        expect(arr.length).to.equal(1);
      });

      // receivers have pacha pass uuid balance
      var promises = addresses.map((address) =>
        nftProducerPachacuy.balanceOf(address, pachaPassUuid)
      );
      var results = await Promise.all(promises);
      results.forEach((result) =>
        expect(result.toString()).to.equal(String(1))
      );
    });

    it("Test pachapass permission - type 1", async () => {
      var pachaUuid = 6; // alice's pacha

      // true
      var accounts = [earl, fephe, gary, huidobro].map((acc) => acc.address);
      var promises = accounts.map((address) =>
        nftProducerPachacuy.isGuineaPigAllowedInPacha(address, pachaUuid)
      );
      var responses = await Promise.all(promises);
      responses.forEach((res) => expect(res).to.be.true);

      // false
      var accounts = [alice, bob, carl, deysi].map((acc) => acc.address);
      var promises = accounts.map((address) =>
        nftProducerPachacuy.isGuineaPigAllowedInPacha(address, pachaUuid)
      );
      var responses = await Promise.all(promises);
      responses.forEach((res) => expect(res).to.be.false);
    });

    it("Test pachapass permission - type 2", async () => {
      var pachaUuid = 7; // bob's pacha

      // true
      var accounts = [fephe, gary, huidobro].map((acc) => acc.address);
      var promises = accounts.map((address) =>
        nftProducerPachacuy.isGuineaPigAllowedInPacha(address, pachaUuid)
      );
      var responses = await Promise.all(promises);
      responses.forEach((res) => expect(res).to.be.true);

      // false
      var accounts = [alice, bob, carl, deysi].map((acc) => acc.address);
      var promises = accounts.map((address) =>
        nftProducerPachacuy.isGuineaPigAllowedInPacha(address, pachaUuid)
      );
      var responses = await Promise.all(promises);
      responses.forEach((res) => expect(res).to.be.false);
    });
  });
});
