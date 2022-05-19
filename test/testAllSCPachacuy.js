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
  var gcf = hre.ethers.getContractFactory;
  var dp = upgrades.deployProxy;
  var signers;
  var pe = ethers.utils.parseEther;

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
      await pachacuyInfo.deployed();

      /**
       * RANDOM NUMBER GENERATOR
       * 1. Set Random Number Generator address as consumer in VRF subscription
       * 2. rng 001 - Add PurchaseAssetController sc within the whitelist of Random Number Generator
       * 2. rng 002 - Add Tatacuy sc within the whitelist of Random Number Generator
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
       * 4. tt 004 - set address of purchase asset controller in Tatacuy
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
       * 2. wi 003 - set address of purchase asset controller in Wiracocha
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
    });

    it("Sets up all Smart Contracts", async () => {
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
      await executeSet(tt, "grantRole", [game_manager, rel], "tt 001");
      await executeSet(tt, "grantRole", [game_manager, nftAdd], "tt 002");
      await executeSet(tt, "grantRole", [rng_generator, rngAdd], "tt 003");
      await executeSet(tt, "setAddPAController", [pacAdd], "tt 004");

      // Wiracocha
      var wi = wiracocha;
      var rel = process.env.RELAYER_ADDRESS_BSC_TESTNET;
      var nftAdd = nftProducerPachacuy.address;
      var pacAdd = purchaseAssetController.address;
      await executeSet(wi, "grantRole", [game_manager, rel], "wi 001");
      await executeSet(wi, "grantRole", [game_manager, nftAdd], "wi 002");
      // await executeSet(wi, "grantRole", [game_manager, pacAdd], "wi 003");
      await executeSet(wi, "setAddPAController", [pacAdd], "wi 004");

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
      await executeSet(pI, "setChakraAddress", [chakra.address], "pI 001");
      await executeSet(pI, "setPoolRewardAddress", [wallet], "pI 002");
      await executeSet(pI, "setHatunWasiAddressAddress", [hwAdd], "pI 008");
      await executeSet(pI, "setTatacuyAddress", [ttc], "pI 009");
      await executeSet(pI, "setWiracochaAddress", [wir], "pI 010");

      // HATUN WASI
      var hw = hatunWasi;
      var nftAdd = nftProducerPachacuy.address;
      await executeSet(hw, "grantRole", [game_manager, nftAdd], "hw 001");
    });

    it("Provides tokens", async () => {
      await pachaCuyToken.mint(alice.address, pe("100000000000000000000000"));
      await pachaCuyToken.mint(bob.address, pe("100000000000000000000000"));

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

  describe("Whitelist", () => {});
});
