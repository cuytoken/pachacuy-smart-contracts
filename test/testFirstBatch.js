const { expect } = require("chai");
const { formatEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const {
  safeAwait,
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
var pe = ethers.utils.parseEther;
var _prefix = "ipfs://QmbbGgo93M6yr5WSUMj53SWN2vC7L6aMS1GZSPNkVRY8e4/";
var testing;
var cw;
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
    qhatuWasiImp,
    vesting,
    Vesting,
    BusinessWallet,
    businessWallet;
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
       * BUSINESS WALLET SMART CONTRACT
       */
      BusinessWallet = await gcf("BusinessWallet");
      businessWallet = await dp(BusinessWallet, [], {
        kind: "uups",
      });
      cw = businessWallet.address;
      /**
       * PACHACUY INFORMATION
       * - pI 001 - set chakra address
       * - pI 002 - set business wallet address
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
      PurchaseAssetController = await gcf("PurchaseAssetController");
      purchaseAssetController = await dp(
        PurchaseAssetController,
        [randomNumberGenerator.address, businessWallet.address],
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
       * GUINEA PIG
       * 1. gp 001 - setPachacuyInfoAddress
       * 2. gp 002 - give role_manager to nftProducer
       */
      GuineaPig = await gcf("GuineaPig");
      guineaPig = await dp(GuineaPig, [], {
        kind: "uups",
      });
      await guineaPig.deployed();

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

      /**
       * VESTING
       */
      Vesting = await gcf("Vesting");
      vesting = await dp(Vesting, [], {
        kind: "uups",
      });
      await vesting.deployed();

      /**
       * Pachacuy Token PCUY
       * 1. Gather all operators and pass it to the initialize
       */

      // PachaCuyToken = await gcf("PachaCuyToken");
      PachaCuyToken = await gcf("ERC777Mock");
      pachaCuyToken = await PachaCuyToken.deploy(
        vesting.address, // _vesting
        owner.address, // _publicSale
        owner.address, // _gameRewards
        owner.address, // _proofOfHold
        owner.address, // _pachacuyEvolution
        [purchaseAssetController.address]
      );
      await pachaCuyToken.deployed();
    });

    it("Sets up all Smart Contracts", async () => {
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
      var rng = randomNumberGenerator;
      var pacAdd = purchaseAssetController.address;
      await executeSet(rng, "addToWhiteList", [pacAdd], "rng 001");

      // PURCHASE ASSET CONTROLLER
      var pac = purchaseAssetController;
      var nftPAdd = nftProducerPachacuy.address;
      var pCuyAdd = pachaCuyToken.address;
      var rngAdd = randomNumberGenerator.address;
      var pIAdd = pachacuyInfo.address;
      await executeSet(pac, "setNftPAddress", [nftPAdd], "PAC 001");
      await executeSet(pac, "setPcuyTokenAddress", [pCuyAdd], "PAC 002");
      await executeSet(pac, "grantRole", [rng_generator, rngAdd], "PAC 003");
      await executeSet(pac, "setPachacuyInfoAddress", [pIAdd], "PAC 006");

      // NFT PRODUCER
      var nftP = nftProducerPachacuy;
      var pacAdd = purchaseAssetController.address;
      var pIAdd = pachacuyInfo.address;
      var pachaAdd = pacha.address;
      await executeSet(nftP, "grantRole", [minter_role, pacAdd], "nftP 001");
      await executeSet(nftP, "setPachacuyInfoaddress", [pIAdd], "nftP 002");
      await executeSet(nftP, "grantRole", [game_manager, pacAdd], "nftP 003");
      await executeSet(nftP, "grantRole", [game_manager, pachaAdd], "nftP 005");
      await executeSet(nftP, "setBurnOp", [allScAdd], "nftP 006");
      await executeSet(nftP, "fillNftsInfo", [nftData], "nftP 007");

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
      await executeSet(pI, "setBizWalletAddress", [wallet], "pI 002");
      await executeSet(pI, "setAddPAController", [pacAdd], "pI 011");
      await executeSet(pI, "setPachaCuyTokenAddress", [pCuyAdd], "pI 012");
      await executeSet(pI, "setNftProducerAddress", [nftAdd], "pI 013");
      await executeSet(pI, "setGuineaPigAddress", [gpAdd], "pI 015");
      await executeSet(pI, "setRandomNumberGAddress", [rngAdd], "pI 016");
      await executeSet(pI, "setBusinessesPrice", [Ps, Ts], "pI 020");

      // GUINEA PIG
      var gp = guineaPig;
      var nftAdd = nftProducerPachacuy.address;
      var pcIAdd = pachacuyInfo.address;
      await executeSet(gp, "setPachacuyInfoAddress", [pcIAdd], "gp 001");
      await executeSet(gp, "grantRole", [game_manager, nftAdd], "gp 002");

      // PACHA
      var pc = pacha;
      var pcIadd = pachacuyInfo.address;
      var nftAdd = nftProducerPachacuy.address;
      await executeSet(pc, "setPachacuyInfoAddress", [pcIadd], "pc 001");
      await executeSet(pc, "grantRole", [game_manager, nftAdd], "pc 002");

      // BUSINESSES SMART CONTRACT
      var bz = businessWallet;
      var pcIadd = pachacuyInfo.address;
      await executeSet(bz, "setPachacuyInfoAddress", [pcIadd], "bz 001");

      // TRANSFER to wallets
      var lq = process.env.WALLET_PACHACUY_LIQUIDITY;
      var pr = process.env.WALLET_PACHACUY_POOL_REWARDS;
      var ph = process.env.WALLET_PACHACUY_PROOF_OF_HOLD;
      var pev = process.env.WALLET_PACHACUY_PACHACUY_EVOLUTION;
      await pachaCuyToken.transfer(lq, pe("29.5"));
      await pachaCuyToken.transfer(pr, pe("30"));
      await pachaCuyToken.transfer(ph, pe("2"));
      await pachaCuyToken.transfer(pev, pe("14"));

      console.log("Final setting finished!");
      console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");

      // init helper
      testing = init(
        purchaseAssetController,
        pachaCuyToken,
        pachacuyInfo,
        pachacuyInfo,
        pachacuyInfo,
        guineaPig,
        guineaPig,
        randomNumberGenerator,
        nftProducerPachacuy,
        businessWallet
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
      // [location, uuid]
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
  });

  describe("Business Wallet", () => {
    it("withdraw", async () => {
      await businessWallet.withdrawFunds(alice.address);
      var bal = await pachaCuyToken.balanceOf(businessWallet.address);
      expect(bal.toString()).to.be.equal(String(0));
    });
  });

  describe("Transfer to wallets", () => {
    it("Verify Balances", async () => {
      var lq = process.env.WALLET_PACHACUY_LIQUIDITY;
      var pr = process.env.WALLET_PACHACUY_POOL_REWARDS;
      var ph = process.env.WALLET_PACHACUY_PROOF_OF_HOLD;
      var pev = process.env.WALLET_PACHACUY_PACHACUY_EVOLUTION;
      var lqBal = await pachaCuyToken.balanceOf(lq);
      var prBal = await pachaCuyToken.balanceOf(pr);
      var phBal = await pachaCuyToken.balanceOf(ph);
      var pevBal = await pachaCuyToken.balanceOf(pev);
      console.log(lqBal.toString());
      console.log(prBal.toString());
      console.log(phBal.toString());
      console.log(pevBal.toString());
    });
  });
});
