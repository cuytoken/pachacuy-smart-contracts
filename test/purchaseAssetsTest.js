const { expect } = require("chai");
const { upgrades, ethers } = require("hardhat");
const {
  getImplementation,
  infoHelper,
  minter_role,
  rng_generator,
} = require("../js-utils/helpers");
const NETWORK = "BSCTESTNET";
upgrades.silenceWarnings();

describe("Purchase Testing", function () {
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
  var gcf = hre.ethers.getContractFactory;
  var dp = upgrades.deployProxy;
  var BN = ethers.BigNumber.from;
  var BUSD = (amount) => BN(`${amount}000000000000000000`);
  var signers;
  var pe = ethers.utils.parseEther;
  var RandomNumberGenerator;
  var randomNumberGenerator;
  var PurchaseAssetController;
  var purchaseAssetController;
  var NftProducerPachacuy;
  var nftProducerPachacuy;
  var BUSDToken;
  var bUSDToken;

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
      // BUSD Token
      BUSDToken = await gcf("BUSD");
      bUSDToken = await dp(BUSDToken, []);
      await bUSDToken.deployed();

      // RNG
      RandomNumberV2Mock = await gcf("RandomNumberV2Mock");
      randomNumberV2Mock = await RandomNumberV2Mock.deploy();
      await randomNumberV2Mock.deployed();

      // PurchaseAssetController
      PurchaseAssetController = await gcf("PurchaseAssetController");
      purchaseAssetController = await dp(
        PurchaseAssetController,
        [
          randomNumberV2Mock.address,
          custodianWallet.address,
          bUSDToken.address,
        ],
        {
          kind: "uups",
        }
      );
      await purchaseAssetController.deployed();

      // Guinea Pig Erc
      var name = "In-game NFT Assets";
      var symbol = "PACHAGAME";
      NftProducerPachacuy = await gcf("NftProducerPachacuy");
      nftProducerPachacuy = await dp(NftProducerPachacuy, [name, symbol], {
        kind: "uups",
      });
      await nftProducerPachacuy.deployed();

      // final setting
      await nftProducerPachacuy.grantRole(
        minter_role,
        purchaseAssetController.address
      );
      await purchaseAssetController.setNftProducerPachacuyAddress(
        nftProducerPachacuy.address
      );
      await purchaseAssetController.grantRole(
        rng_generator,
        randomNumberV2Mock.address
      );
    });
  });

  describe("Purchasing a Guinea Pig", () => {
    var tx;
    var _guineaPigId;
    var ranceAndGender;
    var requestId;
    var randomWords;
    var alicePrevBalance;

    it("Custodian wallet receives money", async () => {
      alicePrevBalance = await bUSDToken.balanceOf(custodianWallet.address);
      await bUSDToken.mint(alice.address, BUSD(100000000000));
      await bUSDToken
        .connect(alice)
        .approve(purchaseAssetController.address, BUSD(100000000000));
      await purchaseAssetController.connect(alice).purchaseGuineaPigWithBusd(3);

      const balance = await bUSDToken.balanceOf(custodianWallet.address);
      expect(balance.toString()).to.equal(BUSD(15).toString());
    });

    it("Balance customer decreases", async () => {
      balance = await bUSDToken.balanceOf(alice.address);
    });

    it("Request for a random number initiated", async () => {
      var res = await randomNumberV2Mock.verifyIfRequestHasBeenCalled(
        purchaseAssetController.address
      );
      expect(res).to.be.true;
    });

    it("Verify that there is an ongoing transaction", async () => {
      var { transactionType, account, ongoing, ix } =
        await purchaseAssetController.getTransactionData(alice.address);
      expect(transactionType).to.equal("PURCHASE_GUINEA_PIG");
      expect(account).to.equal(alice.address);
      expect(ongoing).to.be.true;
      expect(ix).to.equal(3);
    });

    it("Fulfill random number, mint right NFT", async () => {
      // testing _guineaPigId and ranceAndGender
      _guineaPigId = 2;
      var uuid = 0; // counter starts at 0
      ranceAndGender = "INTI MALE";
      requestId = 432423;
      randomWords = [2131432235423, 324325234146];

      tx = await randomNumberV2Mock.fulfillRandomWords(requestId, randomWords);
      await expect(tx)
        .to.emit(purchaseAssetController, "GuineaPigPurchaseFinish")
        .withArgs(
          alice.address,
          BUSD(15).toString(),
          _guineaPigId,
          uuid,
          ranceAndGender
        );

      await expect(tx)
        .to.emit(randomNumberV2Mock, "RandomNumberDelivered")
        .withArgs(
          requestId,
          purchaseAssetController.address,
          alice.address,
          randomWords
        );

      var res = await nftProducerPachacuy.balanceOf(alice.address, uuid);
      expect(res.toNumber()).to.equal(1);
    });

    it("Guinea Pig SC has control over NFT", async () => {
      var res = await nftProducerPachacuy.isApprovedForAll(
        alice.address,
        nftProducerPachacuy.address
      );
      expect(res).to.be.true;
    });
  });

  describe("Verify if random delivers right rance and gender", () => {
    async function mintAndApprove(account) {
      await bUSDToken.mint(account.address, BUSD(100000000000));
      await bUSDToken
        .connect(account)
        .approve(purchaseAssetController.address, BUSD(100000000000));
    }

    async function puchaseWithIndex(account, ix) {
      var tx = await purchaseAssetController
        .connect(account)
        .purchaseGuineaPigWithBusd(ix);
      expect(tx)
        .to.emit(purchaseAssetController, "GuineaPigPurchaseInit")
        .withArgs(
          account.address,
          BUSD(ix * 5).toString(),
          ix,
          custodianWallet.address
        );
    }

    async function fulfillInBatch(
      raceRandomArray,
      genderRandomArray,
      i,
      requestId,
      account,
      randomWords,
      ix,
      resultIds,
      resultRaceGender,
      uuids
    ) {
      var tx = await randomNumberV2Mock.fulfillRandomWords(
        requestId,
        randomWords
      );

      await expect(tx)
        .to.emit(randomNumberV2Mock, "RandomNumberDelivered")
        .withArgs(
          requestId,
          purchaseAssetController.address,
          account.address,
          randomWords
        );

      await expect(tx)
        .to.emit(purchaseAssetController, "GuineaPigPurchaseFinish")
        .withArgs(
          account.address,
          BUSD(ix * 5).toString(),
          resultIds[i],
          uuids[i],
          resultRaceGender[i]
        );

      var res = await nftProducerPachacuy.balanceOf(account.address, uuids[i]);
      expect(res.toNumber()).to.equal(1);
    }

    var resultIds;
    var resultRaceGender;
    var requestId;
    before(async function () {
      resultIds = [1, 5, 2, 6, 3, 7, 4, 8];
      resultRaceGender = [
        "PERU MALE",
        "PERU FEMALE",
        "INTI MALE",
        "INTI FEMALE",
        "ANDINO MALE",
        "ANDINO FEMALE",
        "SINTETICO MALE",
        "SINTETICO FEMALE",
      ];
      requestId = 23423;
    });

    it("Price index 1 (5 BUSD)", async () => {
      // likelihoodRacePriceOne = [70, 85, 95, 100];
      await mintAndApprove(bob);
      var ix = 1;
      var raceRandomArray = [40, 69, 80, 84, 90, 94, 97, 99];
      var genderRandomArray = [2, 1, 2, 1, 2, 1, 2, 1];
      var uuids = [1, 2, 3, 4, 5, 6, 7, 8];

      for (let i = 0; i < raceRandomArray.length; i++) {
        // for (let i = 0; i < 1; i++) {
        await puchaseWithIndex(bob, ix);
        var randomWords = [raceRandomArray[i], genderRandomArray[i]];
        await fulfillInBatch(
          raceRandomArray,
          genderRandomArray,
          i,
          requestId,
          bob,
          randomWords,
          ix,
          resultIds,
          resultRaceGender,
          uuids
        );
      }
    });

    it("Price index 2 (10 BUSD)", async () => {
      // ix = 2;
      // likelihoodRacePriceTwo = [20, 50, 80, 100];
      var ix = 2;
      var raceRandomArray = [10, 19, 40, 49, 55, 79, 91, 99];
      var genderRandomArray = [2, 1, 2, 1, 2, 1, 2, 1];
      var uuids = [9, 10, 11, 12, 13, 14, 15, 16];

      for (let i = 0; i < raceRandomArray.length; i++) {
        // for (let i = 0; i < 1; i++) {
        await puchaseWithIndex(bob, ix);
        var randomWords = [raceRandomArray[i], genderRandomArray[i]];
        await fulfillInBatch(
          raceRandomArray,
          genderRandomArray,
          i,
          requestId,
          bob,
          randomWords,
          ix,
          resultIds,
          resultRaceGender,
          uuids
        );
      }
    });

    it("Price index 3 (15 BUSD)", async () => {
      // ix = 3;
      // likelihoodRacePriceThree = [10, 30, 60, 100];
      var ix = 3;
      var raceRandomArray = [4, 9, 15, 29, 40, 59, 80, 99];
      var genderRandomArray = [2, 1, 2, 1, 2, 1, 2, 1];
      var uuids = [17, 18, 19, 20, 21, 22, 23, 24];

      for (let i = 0; i < raceRandomArray.length; i++) {
        // for (let i = 0; i < 1; i++) {
        await puchaseWithIndex(bob, ix);
        var randomWords = [raceRandomArray[i], genderRandomArray[i]];
        await fulfillInBatch(
          raceRandomArray,
          genderRandomArray,
          i,
          requestId,
          bob,
          randomWords,
          ix,
          resultIds,
          resultRaceGender,
          uuids
        );
      }
    });

    it("Purchase with big numbers", async () => {
      var ix = 3;
      var uuid = 25;
      await puchaseWithIndex(bob, ix);
      var randomWords = [
        BN("8384392923432432908409238409209803924"),
        BN("9298428793394987298473982749823874923"),
      ];

      tx = await randomNumberV2Mock.fulfillRandomWords(requestId, randomWords);
      await expect(tx)
        .to.emit(purchaseAssetController, "GuineaPigPurchaseFinish")
        .withArgs(bob.address, BUSD(15).toString(), 6, uuid, "INTI FEMALE");

      await expect(tx)
        .to.emit(randomNumberV2Mock, "RandomNumberDelivered")
        .withArgs(
          requestId,
          purchaseAssetController.address,
          bob.address,
          randomWords
        );
    });
  });
});
