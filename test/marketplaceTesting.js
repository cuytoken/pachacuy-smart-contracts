const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  infoHelper,
  mintInBatch,
  FENOMENO,
  MISTICO,
  LEGENDARIO,
} = require("../js-utils/helpers");

var bUSD, BUSD, MarketplacePachacuy;

describe("NFT Moche Collection", function () {
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
  var NftProducerPachacuy, nftProducerPachacuy;
  var PachacuyNftCollection, pachacuyNftCollection;
  var gcf = hre.ethers.getContractFactory;
  var dp = upgrades.deployProxy;
  var signers;
  var pe = ethers.utils.parseEther;
  var bn = ethers.BigNumber.from;
  var PCUY;
  var pCUY;

  // 1 BUSD = 25 PCUY
  var ratio = 25;
  var ratioBusdToPcuy = (busdAmount) => busdAmount.mul(ratio);
  var ratioPcuyToBusd = (pcuyAmount) => pcuyAmount.div(ratio);

  // Purchase fee
  var marketPlaceFee = 5;

  // Moche mapping address => uuid
  var mocheMapping = [];
  // Nft Producer mapping address => uuid
  var nftProducerMapping = [];

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

  describe("Set Up", function () {
    var users;
    var price;

    it("Initializes all Smart Contracts", async () => {
      const NETWORK = "BSCTESTNET";

      // BUSD
      BUSD = await gcf("BUSD");
      bUSD = await dp(BUSD, [], {
        kind: "uups",
      });
      await bUSD.deployed();

      var { _tokenName, _tokenSymbol, _nftCurrentPrice, _baseUri } =
        infoHelper(NETWORK);
      PachacuyNftCollection = await gcf("PachacuyNftCollection");
      pachacuyNftCollection = await dp(
        PachacuyNftCollection,
        [
          _tokenName,
          _tokenSymbol,
          200, //_maxSupply
          _nftCurrentPrice,
          bUSD.address,
          process.env.WALLET_FOR_FUNDS,
          _baseUri,
          FENOMENO,
          MISTICO,
          LEGENDARIO,
        ],
        {
          kind: "uups",
        }
      );
      await pachacuyNftCollection.deployed();

      // NFT Producer
      var name = "In-game NFT Pachacuy";
      var symbol = "NFTGAMEPCUY";
      NftProducerPachacuy = await gcf("NftProducerPachacuy");
      nftProducerPachacuy = await dp(NftProducerPachacuy, [name, symbol], {
        kind: "uups",
      });
      await nftProducerPachacuy.deployed();

      // Marketplace
      MarketplacePachacuy = await gcf("MarketplacePachacuy");
      marketplacePachacuy = await dp(
        MarketplacePachacuy,
        [custodianWallet.address, bUSD.address],
        {
          kind: "uups",
        }
      );
      await marketplacePachacuy.deployed();
      await marketplacePachacuy.setErc721Address(pachacuyNftCollection.address);
      await marketplacePachacuy.setErc1155Address(nftProducerPachacuy.address);

      // PCUY
      PCUY = await gcf("ERC777Mock");
      pCUY = await dp(PCUY, [[marketplacePachacuy.address]], {
        kind: "uups",
      });
      await pCUY.deployed();

      // Marketplace set PCUY address
      await marketplacePachacuy.setPachacuyTokenAddress(pCUY.address);
    });

    it("Mints tokens for all users", async () => {
      // minting
      await mintInBatch(owner, signers, bUSD);
      await mintInBatch(owner, signers, pCUY);

      // Minting NFT from Moche
      // Pachacuy NFT collection
      var pachacuySafeMint = pachacuyNftCollection["safeMint(address)"];
      await pachacuySafeMint(alice.address); // 0
      await pachacuySafeMint(bob.address); // 1
      await pachacuySafeMint(carl.address); // 2
      await pachacuySafeMint(deysi.address); // 3
      await pachacuySafeMint(earl.address); // 4
      await pachacuySafeMint(fephe.address); // 5

      // Mintinf NFTs from NFT game
      // mintGuineaPigNft
      await nftProducerPachacuy.mintGuineaPigNft(alice.address, 0, 1, 4, "0x"); // 1
      await nftProducerPachacuy.mintGuineaPigNft(bob.address, 1, 2, 4, "0x"); // 2
      await nftProducerPachacuy.mintGuineaPigNft(carl.address, 0, 3, 4, "0x"); // 3
      await nftProducerPachacuy.mintGuineaPigNft(deysi.address, 1, 4, 4, "0x"); // 4
      await nftProducerPachacuy.mintGuineaPigNft(earl.address, 0, 1, 4, "0x"); // 5
      await nftProducerPachacuy.mintGuineaPigNft(fephe.address, 1, 2, 4, "0x"); // 6

      // mintLandNft
      await nftProducerPachacuy.mintLandNft(alice.address, 1, "0x"); // 7
      await nftProducerPachacuy.mintLandNft(bob.address, 10, "0x"); // 8
      await nftProducerPachacuy.mintLandNft(carl.address, 20, "0x"); // 9
      await nftProducerPachacuy.mintLandNft(deysi.address, 30, "0x"); // 10
      await nftProducerPachacuy.mintLandNft(earl.address, 40, "0x"); // 11
      await nftProducerPachacuy.mintLandNft(fephe.address, 50, "0x"); // 12

      // mintPachaPassNft
      // uuid of this pachapass is 13
      await nftProducerPachacuy.connect(bob).setPachaToPrivateAndDistribution(
        8, // _landUuid
        pe("1000000"), // price
        2, // typeOfDistribution
        []
      );
      await nftProducerPachacuy.mintPachaPassNft(
        alice.address, // account
        8, // _landUuid
        13, // _uuidPachaPass
        2, // _typeOfDistribution
        pe("1000000"), // _price
        "purchased" // _transferMode
      );
    });
  });

  describe("Marketplace Permission", () => {
    it("Gives permission from Moche SC", async function () {
      users = [alice, bob, carl, deysi];
      await Promise.all(
        users.map((user) =>
          pachacuyNftCollection
            .connect(user)
            .setApprovalForAll(marketplacePachacuy.address, true)
        )
      );
    });

    it("Gives permission from Game SC", async function () {
      var users = [alice, bob, carl, deysi];
      await Promise.all(
        users.map((user) =>
          nftProducerPachacuy
            .connect(user)
            .setApprovalForAll(marketplacePachacuy.address, true)
        )
      );
    });
  });

  describe("Marketplace listing", () => {
    users = [alice, bob, carl, deysi];

    it("Lists items in Marketplace", async () => {
      price = pe("1000");

      // Pachacuy NFT Producer
      await Promise.all(
        users.map((user, ix) => {
          var i = ix + 1;
          nftProducerMapping[ix] = {
            uuid: String(i),
            scAddress: nftProducerPachacuy.address,
            owner: user.address,
          };
          return marketplacePachacuy
            .connect(user)
            .setPriceAndListAsset(nftProducerPachacuy.address, i, price);
        })
      );

      // Moche NFT
      await Promise.all(
        users.map((user, ix) => {
          mocheMapping[ix] = {
            uuid: String(ix),
            scAddress: pachacuyNftCollection.address,
            owner: user.address,
          };
          return marketplacePachacuy
            .connect(user)
            .setPriceAndListAsset(pachacuyNftCollection.address, ix, price);
        })
      );

      var _list = await marketplacePachacuy.getListOfNftsForSale();
      expect(_list.length).to.equal(8);
    });

    it("An item cannot be listed twice", async function () {
      await Promise.all(
        users.map((user, ix) =>
          expect(
            marketplacePachacuy
              .connect(user)
              .setPriceAndListAsset(pachacuyNftCollection.address, ix, price)
          ).to.revertedWith("Marketplace: NFT is already listed")
        )
      );

      await Promise.all(
        users.map((user, ix) =>
          expect(
            marketplacePachacuy
              .connect(user)
              .setPriceAndListAsset(nftProducerPachacuy.address, ix + 1, price)
          ).to.revertedWith("Marketplace: NFT is already listed")
        )
      );
    });

    it("A user cannot list an item if it is not his", async () => {
      await expect(
        marketplacePachacuy
          .connect(alice)
          .setPriceAndListAsset(nftProducerPachacuy.address, 5, price)
      ).to.revertedWith(
        "Marketplace: (1155) Caller is not the owner of this UUID"
      );

      await expect(
        marketplacePachacuy
          .connect(alice)
          .setPriceAndListAsset(pachacuyNftCollection.address, 4, price)
      ).to.revertedWith(
        "Marketplace: (721) Caller is not the owner of this UUID"
      );
    });

    it("Fails when user did not give permission", async () => {
      users = [earl, fephe];
      await Promise.all(
        users.map((user, ix) =>
          expect(
            marketplacePachacuy
              .connect(earl)
              .setPriceAndListAsset(
                pachacuyNftCollection.address,
                ix + 4,
                price
              )
          ).to.revertedWith(
            "Marketplace: Permission was not give to Marketplace SC"
          )
        )
      );

      await Promise.all(
        users.map((user, ix) =>
          expect(
            marketplacePachacuy
              .connect(earl)
              .setPriceAndListAsset(
                nftProducerPachacuy.address,
                ix + 4 + 1,
                price
              )
          ).to.revertedWith(
            "Marketplace: Permission was not give to Marketplace SC"
          )
        )
      );
    });
  });

  describe("Marketplace puchase NFT BUSD", () => {
    var _balancePcuyCWallet;
    var _balanceBusdCWallet;
    var _balancePcuyAlice;
    var _balanceBusdAlice;
    var uuid;
    var listToCheckedAgainst;

    it("Executes purchase - Moche", async function () {
      _balanceBusdCWallet = await bUSD.balanceOf(custodianWallet.address);
      _balanceBusdAlice = await bUSD.balanceOf(alice.address);

      // Moche Pachacuy Collection NFT 721
      var amountToApprove = ratioPcuyToBusd(ethers.BigNumber.from(price));
      await bUSD
        .connect(gary)
        .approve(marketplacePachacuy.address, amountToApprove);
      uuid = 0;
      await marketplacePachacuy
        .connect(gary)
        .purchaseNftWithBusd(pachacuyNftCollection.address, uuid);
    });

    it("Coorect Uuid - 0 was take out from list", async () => {
      var uuidRemoved = String(0);
      var _list = await marketplacePachacuy.getListOfNftsForSale();
      expect(_list.length).to.equal(7);
      listToCheckedAgainst = [...nftProducerMapping, ...mocheMapping].filter(
        (el) =>
          !(
            String(el.uuid) === uuidRemoved &&
            el.scAddress === pachacuyNftCollection.address
          )
      );

      for (var i = 0; i < listToCheckedAgainst.length; i++) {
        var { uuid, scAddress, owner } = listToCheckedAgainst[i];
        var temp = _list.filter((el) => {
          var [_owner, _scAddress, _uuid] = el;
          return (
            uuid === _uuid.toString() &&
            _scAddress === scAddress &&
            owner === _owner
          );
        });
        expect(temp.length).to.be.greaterThan(0);
      }
    });

    it("NFT ownership is transferred - Moche", async () => {
      // ERC721
      var _owner = await pachacuyNftCollection.ownerOf(uuid);
      expect(_owner).to.equal(gary.address);
    });

    it("Fee is deposited to custodian wallet - Moche", async () => {
      var fee = ratioPcuyToBusd(bn(price)).mul(marketPlaceFee).div(bn("100"));
      var net = ratioPcuyToBusd(bn(price)).sub(fee);
      var _busdCWalletAFter = await bUSD.balanceOf(custodianWallet.address);
      expect(_busdCWalletAFter.sub(_balanceBusdCWallet).toString()).to.equal(
        fee.toString()
      );
    });

    it("NFT owner receives net in USD (minus fee) - Moche", async () => {
      var fee = ratioPcuyToBusd(bn(price)).mul(marketPlaceFee).div(bn("100"));
      var net = ratioPcuyToBusd(bn(price)).sub(fee);
      var _balanceBusdAliceAfter = await bUSD.balanceOf(alice.address);
      expect(_balanceBusdAliceAfter.sub(_balanceBusdAlice).toString()).to.equal(
        net.toString()
      );
    });

    it("Same NFT cannot be purchased twice - Moche", async () => {
      var amountToApprove = ratioPcuyToBusd(ethers.BigNumber.from(price));
      await bUSD
        .connect(gary)
        .approve(marketplacePachacuy.address, amountToApprove);
      uuid = 0;
      await expect(
        marketplacePachacuy
          .connect(gary)
          .purchaseNftWithBusd(pachacuyNftCollection.address, uuid)
      ).to.revertedWith("Marketplace: NFT is not listed");
    });

    it("Executes purchase - ERC1155", async function () {
      _balanceBusdCWallet = await bUSD.balanceOf(custodianWallet.address);
      _balanceBusdAlice = await bUSD.balanceOf(alice.address);

      // Game ERC1155
      var amountToApprove = ratioPcuyToBusd(ethers.BigNumber.from(price));
      await bUSD
        .connect(huidobro)
        .approve(marketplacePachacuy.address, amountToApprove);
      var uuid = 1;
      await marketplacePachacuy
        .connect(huidobro)
        .purchaseNftWithBusd(nftProducerPachacuy.address, uuid);
    });

    it("Coorect Uuid - 1 was take out from list - erc1155", async () => {
      var uuidRemoved = String(1);
      var _list = await marketplacePachacuy.getListOfNftsForSale();
      expect(_list.length).to.equal(6);

      listToCheckedAgainst = listToCheckedAgainst.filter(
        (el) =>
          !(
            String(el.uuid) === uuidRemoved &&
            el.scAddress === nftProducerPachacuy.address
          )
      );

      for (var i = 0; i < listToCheckedAgainst.length; i++) {
        var { uuid, scAddress, owner } = listToCheckedAgainst[i];
        var temp = _list.filter((el) => {
          var [_owner, _scAddress, _uuid] = el;
          return (
            uuid === _uuid.toString() &&
            _scAddress === scAddress &&
            owner === _owner
          );
        });
        expect(temp.length).to.be.greaterThan(0);
      }
    });

    it("NFT ownership is transferred - ERC1155", async () => {
      // ERC1155
      var uuid = 1;
      var _balance = await nftProducerPachacuy.balanceOf(
        huidobro.address,
        uuid
      );
      expect(_balance.toString()).to.equal(String(1));
      var _balance = await nftProducerPachacuy.balanceOf(alice.address, uuid);
      expect(_balance.toString()).to.equal(String(0));
    });

    it("Fee is deposited to custodian wallet - ERC1155", async () => {
      var fee = ratioPcuyToBusd(bn(price)).mul(marketPlaceFee).div(bn("100"));
      var net = ratioPcuyToBusd(bn(price)).sub(fee);
      var _busdCWalletAFter = await bUSD.balanceOf(custodianWallet.address);
      expect(_busdCWalletAFter.sub(_balanceBusdCWallet).toString()).to.equal(
        fee.toString()
      );
    });

    it("NFT owner receives net in USD (minus fee) - ERC1155", async () => {
      var fee = ratioPcuyToBusd(bn(price)).mul(marketPlaceFee).div(bn("100"));
      var net = ratioPcuyToBusd(bn(price)).sub(fee);
      var _balanceBusdAliceAfter = await bUSD.balanceOf(alice.address);
      expect(_balanceBusdAliceAfter.sub(_balanceBusdAlice).toString()).to.equal(
        net.toString()
      );
    });

    it("Same NFT cannot be purchased twice - ERC1155", async () => {
      var amountToApprove = ratioPcuyToBusd(ethers.BigNumber.from(price));
      await bUSD
        .connect(huidobro)
        .approve(marketplacePachacuy.address, amountToApprove);
      var uuid = 1;
      await expect(
        marketplacePachacuy
          .connect(huidobro)
          .purchaseNftWithBusd(nftProducerPachacuy.address, uuid)
      ).to.revertedWith("Marketplace: NFT is not listed");
    });

    it("A user puchase all NFTs from nftP ERC1155", async function () {
      var _nftProducerUuids = [2, 3, 4];

      var amountToApprove = ratioPcuyToBusd(ethers.BigNumber.from(price)).mul(
        bn(3)
      );
      await bUSD
        .connect(gary)
        .approve(marketplacePachacuy.address, amountToApprove);

      await Promise.all(
        _nftProducerUuids.map((uuid, ix) =>
          marketplacePachacuy
            .connect(gary)
            .purchaseNftWithBusd(nftProducerPachacuy.address, uuid)
        )
      );
    });

    it("Verifies that NFTs are not in the list anymore", async function () {
      var _list = await marketplacePachacuy.getListOfNftsForSale();
      expect(_list.length).to.equal(3);
      var _rest = _list.filter((el) => {
        var [owner, scAddress, uuid] = el;
        return scAddress === nftProducerPachacuy.address;
      });
      expect(_rest.length).to.equal(0);
    });

    it("A user puchase all Moche NFTs ERC721", async function () {
      var _mocheNftsUuids = [1, 2];
      var amountToApprove = ratioPcuyToBusd(ethers.BigNumber.from(price)).mul(
        bn(3)
      );
      await bUSD
        .connect(huidobro)
        .approve(marketplacePachacuy.address, amountToApprove);

      await Promise.all(
        _mocheNftsUuids.map((uuid, ix) =>
          marketplacePachacuy
            .connect(huidobro)
            .purchaseNftWithBusd(pachacuyNftCollection.address, uuid)
        )
      );
      var _list = await marketplacePachacuy.getListOfNftsForSale();
      var [, , _uuid] = _list[0];
      expect(_uuid.toString()).to.equal(String(3));

      await marketplacePachacuy
        .connect(huidobro)
        .purchaseNftWithBusd(pachacuyNftCollection.address, 3);

      var _list = await marketplacePachacuy.getListOfNftsForSale();
      expect(_list.length).to.equal(0);
    });
  });
});
