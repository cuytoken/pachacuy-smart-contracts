const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  infoHelper,
  mintInBatch,
  FENOMENO,
  MISTICO,
  LEGENDARIO,
} = require("../js-utils/helpers");

var bUSD, pcuyNFTC, BUSD, MarketplacePachacuy, baseUri;

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
  var gcf = hre.ethers.getContractFactory;
  var dp = upgrades.deployProxy;
  var signers;
  var pe = ethers.utils.parseEther;
  ethers.Signer;

  before(async function () {
    /**
     * @type import ('@nomiclabs/src').SignerWithAddress
     */
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
      const PachacuyNftCollection = await gcf("PachacuyNftCollection");
      const pachacuyNftCollection = await dp(
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

      // PCUY
      var PCUY = await gcf("ERC777Mock");
      var pCUY = await dp(PCUY, [[owner.address]], {
        kind: "uups",
      });
      await pCUY.deployed();

      // Marketplace
      MarketplacePachacuy = await gcf("MarketplacePachacuy");
      marketplacePachacuy = await dp(
        MarketplacePachacuy,
        [custodianWallet.address, bUSD.address, pCUY.address],
        {
          kind: "uups",
        }
      );
      await marketplacePachacuy.deployed();

      // minting
      await mintInBatch(owner, signers, bUSD);
      await mintInBatch(owner, signers, pCUY);

      // Minting NFT from Moche

      // Mintinf NFTs from NFT game
      // mintGuineaPigNft
      await nftProducerPachacuy.mintGuineaPigNft(bob.address, 1, 2, 4, "0x"); // 1
      await nftProducerPachacuy.mintGuineaPigNft(carl.address, 0, 3, 4, "0x"); // 2
      await nftProducerPachacuy.mintGuineaPigNft(deysi.address, 1, 4, 4, "0x"); // 3
      await nftProducerPachacuy.mintGuineaPigNft(earl.address, 0, 1, 4, "0x"); // 4
      await nftProducerPachacuy.mintGuineaPigNft(fephe.address, 1, 2, 4, "0x"); // 5
      await nftProducerPachacuy.mintGuineaPigNft(alice.address, 0, 1, 4, "0x"); // 6

      // mintLandNft
      await nftProducerPachacuy.mintLandNft(bob.address, 10, "0x"); // 7
      await nftProducerPachacuy.mintLandNft(carl.address, 20, "0x"); // 8
      await nftProducerPachacuy.mintLandNft(deysi.address, 30, "0x"); // 9
      await nftProducerPachacuy.mintLandNft(earl.address, 40, "0x"); // 10
      await nftProducerPachacuy.mintLandNft(fephe.address, 50, "0x"); // 11
      await nftProducerPachacuy.mintLandNft(alice.address, 1, "0x"); // 12

      // mintPachaPassNft
      // uuid of this pachapass is 13
      await nftProducerPachacuy.connect(bob).setPachaToPrivateAndDistribution(
        7, // _landUuid
        pe("1000000"), // price
        2, // typeOfDistribution
        []
      );
      await nftProducerPachacuy.mintPachaPassNft(
        alice.address, // account
        7, // _landUuid
        13, // _uuidPachaPass
        2, // _typeOfDistribution
        pe("1000000"), // _price
        "purchased" // _transferMode
      );
    });
  });

  describe("Marketplace", () => {
    it("Gives permission from Moche SC", async function () {});

    it("Gives permission from Game SC", async function () {
      await nftProducerPachacuy
        .connect(alice)
        .setApprovalForAll(marketplacePachacuy.address, true);
    });
  });
});
