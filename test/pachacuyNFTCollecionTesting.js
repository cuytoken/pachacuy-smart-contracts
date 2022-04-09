const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  getImplementation,
  infoHelper,
  FENOMENO,
  MISTICO,
  LEGENDARIO,
} = require("../js-utils/helpers");
var bUSD, pcuyNFTC, BUSD, PachacuyNftCollection, baseUri;

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
  var gcf = hre.ethers.getContractFactory;
  var dp = upgrades.deployProxy;
  var signers;
  var pe = ethers.utils.parseEther;
  var currIx;
  var nftCurrentPrice;
  var maxSupply;

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
      // BUSD
      BUSD = await gcf("BUSD");
      bUSD = await dp(BUSD, []);
      await bUSD.deployed();
      const NETWORK = "BSCTESTNET";

      // FNT
      var {
        _busdToken,
        _tokenName,
        _tokenSymbol,
        _maxSupply,
        _nftCurrentPrice,
        _baseUri,
      } = infoHelper(NETWORK);
      maxSupply = _maxSupply;
      baseUri = _baseUri;
      PachacuyNftCollection = await gcf("PachacuyNftCollection");
      pcuyNFTC = await dp(
        PachacuyNftCollection,
        [
          _tokenName,
          _tokenSymbol,
          _maxSupply,
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
      nftCurrentPrice = _nftCurrentPrice;
      await pcuyNFTC.deployed();

      // minting
      await bUSD.mint(owner.address, pe(String(`${10 ** 6}`)));
      await bUSD.mint(alice.address, pe(String(`${10 ** 6}`)));
      await bUSD.mint(bob.address, pe(String(`${10 ** 6}`)));
      await bUSD.mint(carl.address, pe(String(`${10 ** 6}`)));
      await bUSD.mint(deysi.address, pe(String(`${10 ** 6}`)));
      await bUSD.mint(earl.address, pe(String(`${10 ** 6}`)));
      await bUSD.mint(fephe.address, pe(String(`${10 ** 6}`)));
      await bUSD.mint(gary.address, pe(String(`${10 ** 6}`)));
      await bUSD.mint(huidobro.address, pe(String(`${10 ** 6}`)));
      await bUSD.mint(custodianWallet.address, pe(String(`${10 ** 6}`)));
    });
  });

  describe("Whitelist", () => {
    var whitelistArr;
    var whitelistAddArr;

    it("Adds addresses to whitelist", async function () {
      whitelistArr = [...signers].splice(15);
      whitelistAddArr = whitelistArr.map((signer) => signer.address);
      await pcuyNFTC.addToWhitelistBatch(whitelistAddArr);
    });

    it("Delivers NFTs to whitelist addresses", async function () {
      var r = whitelistArr.map(
        (el) => () => pcuyNFTC.connect(el).claimFreeNftByWhitelist()
      );
      await Promise.all(
        whitelistArr.map((el) => pcuyNFTC.connect(el).claimFreeNftByWhitelist())
      );

      // 5 nft minted
      // ix[] => [0, 1, 2, 3, 4]
      var tx = await pcuyNFTC.totalSupply();
      expect(tx.toString()).equal(String(whitelistArr.length));
    });

    it("A non-whitelist address cannot claimed a free NFT", async function () {
      await expect(
        pcuyNFTC.connect(signers[10]).claimFreeNftByWhitelist()
      ).to.revertedWith(
        "Pachacuy NFT Collection: Account is not in whitelist."
      );

      await expect(
        pcuyNFTC.connect(signers[9]).claimFreeNftByWhitelist()
      ).to.revertedWith(
        "Pachacuy NFT Collection: Account is not in whitelist."
      );
    });

    it("A whitelist address cannot claimed more than one NFT", async function () {
      await expect(
        pcuyNFTC.connect(whitelistArr[4]).claimFreeNftByWhitelist()
      ).to.revertedWith(
        "Pachacuy NFT Collection: Whitelist account already claimed one NFT."
      );
      await expect(
        pcuyNFTC.connect(whitelistArr[0]).claimFreeNftByWhitelist()
      ).to.revertedWith(
        "Pachacuy NFT Collection: Whitelist account already claimed one NFT."
      );
    });

    it("A whitelist address cannot claimed a reserved NFT", async function () {
      // gets index of current NFT
      var ix = await pcuyNFTC.totalSupply();
      currIx = ix.toNumber(); // 5

      // adds ix within reserved NFT list
      await pcuyNFTC.addReservedNftIdsBatch([ix.toNumber()]); // ix 5 reserved
      await pcuyNFTC.addReservedNftIdsBatch([ix.toNumber() + 1]); // ix 6 reserved
      await pcuyNFTC.addReservedNftIdsBatch([ix.toNumber() + 2]); // ix 7 reserved

      // get a signer #10 and add it to the white list. Then claim a NFT
      whitelistAddArr = [signers[10].address];
      await pcuyNFTC.addToWhitelistBatch(whitelistAddArr);
      await pcuyNFTC.connect(signers[10]).claimFreeNftByWhitelist();

      // should not get NFT at position ix (5,6,7 - reserved) but in position ix + 3 (8)
      var owner = await pcuyNFTC.ownerOf(ix.toNumber() + 3);
      expect(owner).equal(whitelistAddArr[0]);

      // should revert for ix, ix + 1 and ix + 2 (non minted and reserved)
      await expect(pcuyNFTC.ownerOf(ix.toNumber())).to.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
      await expect(pcuyNFTC.ownerOf(ix.toNumber() + 1)).to.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
      await expect(pcuyNFTC.ownerOf(ix.toNumber() + 2)).to.revertedWith(
        "ERC721: owner query for nonexistent token"
      );

      var supply = await pcuyNFTC.totalSupply();
      expect(ix.toNumber() + 1).equal(supply.toNumber());
    });
  });

  describe("Purchase without ID", () => {
    var balancePrevAlice;
    var balanceAfterAlice;
    var balancePrevBob;
    var balanceAfterBob;
    var balancePrevCarl;
    var balanceAfterCarl;

    it("Purchase NFt with BUSD without ID", async () => {
      balancePrevAlice = await bUSD.balanceOf(alice.address);
      balancePrevBob = await bUSD.balanceOf(bob.address);
      // minted ix: 0 - 4
      // reserved 5, 6, 7
      // minted ix: 8
      // total supply: 6
      currIx += 4; // 9
      await bUSD.connect(alice).approve(pcuyNFTC.address, pe("1000000"));
      await bUSD.connect(bob).approve(pcuyNFTC.address, pe("1000000"));
      await pcuyNFTC.connect(alice).purchaseNftWithBusd();
      await pcuyNFTC.connect(bob).purchaseNftWithBusd();
      var owner = await pcuyNFTC.ownerOf(currIx);
      expect(owner).equal(alice.address);
      var owner = await pcuyNFTC.ownerOf(currIx + 1);
      expect(owner).equal(bob.address);
      var supply = await pcuyNFTC.totalSupply();
      expect(supply.toNumber()).equal(8);
    });

    it("Balance from purchaser should decrease", async () => {
      balanceAfterAlice = await bUSD.balanceOf(alice.address);
      expect(balancePrevAlice.sub(balanceAfterAlice).toString()).equal(
        nftCurrentPrice
      );
      balanceAfterBob = await bUSD.balanceOf(bob.address);
      expect(balancePrevBob.sub(balanceAfterBob).toString()).equal(
        nftCurrentPrice
      );
    });

    it("Cannot purchase a reserved NFT", async () => {
      balancePrevCarl = await bUSD.balanceOf(carl.address);
      await bUSD.connect(carl).approve(pcuyNFTC.address, pe("1000000"));

      currIx += 2; // 11
      await pcuyNFTC.addReservedNftIdsBatch([currIx]); // ix 11 reserved

      // purchase ix 12 (minted and owneb y Carl)
      await pcuyNFTC.connect(carl).purchaseNftWithBusd();
      var owner = await pcuyNFTC.ownerOf(currIx + 1);
      expect(owner).equal(carl.address);
    });
  });
  describe("Purchase with ID", () => {
    it("Purchasing a reserved NFT is not possible", async () => {
      // minted ix: 0 - 4
      // reserved 5, 6, 7
      // minted ix: 8, 9, 10
      // reserved: 11
      // minted: 12
      await bUSD.connect(deysi).approve(pcuyNFTC.address, pe("1000000"));
      var reserved = [5, 6, 7, 11];
      await Promise.all(
        reserved.map((num) =>
          expect(
            pcuyNFTC.connect(deysi).purchaseNftWithBusdAndId(num)
          ).to.revertedWith(
            "Pachacuy NFT Collection: You cannot mint a Reserved NFT ID."
          )
        )
      );
    });

    it("Cannot mint a minted NFT with owner", async () => {
      var minted = [0, 1, 2, 3, 4, 8, 9, 10, 12];
      await Promise.all(
        minted.map((num) =>
          expect(
            pcuyNFTC.connect(deysi).purchaseNftWithBusdAndId(num)
          ).to.revertedWith(
            "Pachacuy NFT Collection: This NFT id has been minted already."
          )
        )
      );
    });

    it("Should be able to purchase an NFT with ID", async () => {
      currIx = 13;
      await pcuyNFTC.connect(deysi).purchaseNftWithBusdAndId(currIx);
      var owner = await pcuyNFTC.ownerOf(currIx);
      expect(owner).equal(deysi.address);
    });

    it("Should be able to purchase multiple NFT with ID", async () => {
      // 14
      currIx++;
      await pcuyNFTC.connect(deysi).purchaseNftWithBusdAndId(currIx);
      var owner = await pcuyNFTC.ownerOf(currIx);
      expect(owner).equal(deysi.address);

      // 15
      currIx++;
      await pcuyNFTC.connect(deysi).purchaseNftWithBusdAndId(currIx);
      var owner = await pcuyNFTC.ownerOf(currIx);
      expect(owner).equal(deysi.address);

      // 16
      currIx++;
      await pcuyNFTC.connect(deysi).purchaseNftWithBusdAndId(currIx);
      var owner = await pcuyNFTC.ownerOf(currIx);
      expect(owner).equal(deysi.address);
    });

    it("Should reach its limit and fail", async () => {
      var reserved = [17, 18, 19];
      await pcuyNFTC.addReservedNftIdsBatch(reserved); // ix 17, 18, 19 reserved
      var supply = await pcuyNFTC.totalSupply();
      await expect(
        pcuyNFTC.connect(deysi).purchaseNftWithBusd()
      ).to.revertedWith(
        "Pachachuy NFT Collection: the ID count has reached its maximun supply."
      );
    });

    it("Cannot purchase an ID out of bunds", async () => {
      await expect(
        pcuyNFTC.connect(deysi).purchaseNftWithBusdAndId(maxSupply)
      ).to.revertedWith("Pachacuy NFT Collection: ID pass it not valid.");
      await expect(
        pcuyNFTC.connect(deysi).purchaseNftWithBusdAndId(maxSupply + 1)
      ).to.revertedWith("Pachacuy NFT Collection: ID pass it not valid.");
    });
  });

  describe("URI", () => {
    it("Returns a URI for existent token", async () => {
      var uri = await pcuyNFTC.tokenURI(4);
      expect(uri).equal(`${baseUri}4.json`);
      var uri = await pcuyNFTC.tokenURI(3);
      expect(uri).equal(`${baseUri}3.json`);
      var uri = await pcuyNFTC.tokenURI(2);
      expect(uri).equal(`${baseUri}2.json`);
      var uri = await pcuyNFTC.tokenURI(1);
      expect(uri).equal(`${baseUri}1.json`);
      var uri = await pcuyNFTC.tokenURI(0);
      expect(uri).equal(`${baseUri}0.json`);
    });

    it("URI Reverts when token does not exist", async () => {
      await expect(pcuyNFTC.tokenURI(17)).to.revertedWith(
        "ERC721Metadata: URI query for nonexistent token"
      );
      await expect(pcuyNFTC.tokenURI(18)).to.revertedWith(
        "ERC721Metadata: URI query for nonexistent token"
      );
      await expect(pcuyNFTC.tokenURI(19)).to.revertedWith(
        "ERC721Metadata: URI query for nonexistent token"
      );
    });
  });

  describe("Reserved tokens", () => {
    it("Mint reserved tokens", async () => {
      var reserved = [17, 18, 19, 5, 6, 7, 11];
      await Promise.all(
        reserved.map((num) =>
          pcuyNFTC
            .connect(owner)
            ["safeMint(address,uint256)"](alice.address, num)
        )
      );
    });

    it("Minting a token with owner should fail", async () => {
      await expect(
        pcuyNFTC.connect(owner)["safeMint(address,uint256)"](alice.address, 18)
      ).to.revertedWith(
        "Pachacuy NFT Collection: This NFT id has been minted already."
      );
    });

    it("Total supply should be matched", async () => {
      var supply = await pcuyNFTC.totalSupply();
      expect(supply.toNumber()).equal(maxSupply);
    });
  });
});

/**
 * it("Purchase reserved NFTs with/without role", async function () {});
    
 */
