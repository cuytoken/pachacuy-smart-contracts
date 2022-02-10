const { expect } = require("chai");
const { ethers } = require("hardhat");
const { getImplementation, infoHelper } = require("../js-utils/helpers");

function setUpPurchaseTokens(
  privateSaleOne,
  pachaCuyBSC,
  custodianWallet,
  _exchangeRatePrivateSaleOne,
  MAX
) {
  return async function purchaseTokens(
    busdSpent,
    prevBalance,
    customer,
    customerAddress
  ) {
    var balancePrevCustodianWallet = await pachaCuyBSC.balanceOf(
      custodianWallet.address
    );
    await privateSaleOne.connect(customer).purchaseTokensWithBusd(busdSpent);
    var balance = await pachaCuyBSC.balanceOf(customerAddress);
    expect(balance.toString()).equal(prevBalance.sub(busdSpent).toString());
    var balance = await pachaCuyBSC.balanceOf(custodianWallet.address);
    expect(balance.toString()).equal(
      balancePrevCustodianWallet.add(busdSpent).toString()
    );
    var { _walletCusomter, _busdSpent, _pachacuyPurchased, _rate } =
      await privateSaleOne.queryBalance(customerAddress);
    expect(_walletCusomter).equal(customerAddress);
    expect(_busdSpent.toString()).equal(busdSpent.toString());
    var amountPachacuyPurchased = busdSpent.mul(
      ethers.BigNumber.from(_exchangeRatePrivateSaleOne)
    );
    expect(_pachacuyPurchased.toString()).equal(
      amountPachacuyPurchased.toString()
    );

    var listOfCustomers = await privateSaleOne.retrieveListOfCustomers();
    var listOfCustomersPromises = listOfCustomers.map(function (customer) {
      return privateSaleOne.queryBalance(customer);
    });
    var totalPCArr = await Promise.all(listOfCustomersPromises);
    var totalPachacuyPurchased = totalPCArr.reduce(function (prev, current) {
      var { _pachacuyPurchased } = current;
      return _pachacuyPurchased.add(prev);
    }, ethers.BigNumber.from("0"));
    var leftToSell = await privateSaleOne.amountPachacuyLeftToSell();
    expect(leftToSell.toString()).equal(
      MAX.sub(totalPachacuyPurchased).toString()
    );
  };
}

describe("Pachacuy Private Sale", function () {
  var PachaCuyBSC,
    pachaCuyBSC,
    PrivateSaleOne,
    privateSaleOne,
    airdrop,
    RNGMock,
    rNGMock;
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
  var { _exchangeRatePrivateSaleOne } = infoHelper(NET);
  var MAX = ethers.BigNumber.from("1500000").mul("1000000000000000000");
  var NET = "BSCTESTNET"; // BSCTESTNET

  function tokens(amount) {
    let bn = ethers.BigNumber.from;
    return bn(amount).mul("1000000000000000000");
  }

  var purchaseTokens;

  before(async function () {
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
    ] = await ethers.getSigners();
  });

  describe("Private Sale One", function () {
    it("Setting up smart contracts", async function () {
      // PachaCuyBSC
      PachaCuyBSC = await hre.ethers.getContractFactory("PachaCuyBSC");
      pachaCuyBSC = await upgrades.deployProxy(PachaCuyBSC, []);
      await pachaCuyBSC.deployed();
      var implementationAddress = await getImplementation(pachaCuyBSC.address);

      // Private Sale One
      PrivateSaleOne = await hre.ethers.getContractFactory("PrivateSaleOne");
      privateSaleOne = await upgrades.deployProxy(PrivateSaleOne, [
        pachaCuyBSC.address,
        custodianWallet.address,
        _exchangeRatePrivateSaleOne,
      ]);
      await privateSaleOne.deployed();
      var implementationAddressPS = await getImplementation(
        privateSaleOne.address
      );

      // setting purchase function
      purchaseTokens = setUpPurchaseTokens(
        privateSaleOne,
        pachaCuyBSC,
        custodianWallet,
        _exchangeRatePrivateSaleOne,
        MAX
      );
    });

    it("Minting and balances match", async function () {
      await pachaCuyBSC.mint(alice.address, tokens(1000));
      await pachaCuyBSC.mint(bob.address, tokens(2000));
      await pachaCuyBSC.mint(carl.address, tokens(4000));
      await pachaCuyBSC.mint(deysi.address, tokens(300));
      await pachaCuyBSC.mint(earl.address, tokens(100));

      var balance = await pachaCuyBSC.balanceOf(alice.address);
      expect(balance.toString()).equal(tokens(1000).toString());
      var balance = await pachaCuyBSC.balanceOf(bob.address);
      expect(balance.toString()).equal(tokens(2000).toString());
      var balance = await pachaCuyBSC.balanceOf(carl.address);
      expect(balance.toString()).equal(tokens(4000).toString());
      var balance = await pachaCuyBSC.balanceOf(deysi.address);
      expect(balance.toString()).equal(tokens(300).toString());
      var balance = await pachaCuyBSC.balanceOf(earl.address);
      expect(balance.toString()).equal(tokens(100).toString());
    });

    it("Customers not in whitelist then fails", async function () {
      await privateSaleOne.enableWhitelistFilter();
      await expect(
        privateSaleOne.connect(alice).purchaseTokensWithBusd(tokens(300))
      ).to.be.revertedWith("Private Sale: Customer is not in Whitelist.");
      await expect(
        privateSaleOne.connect(bob).purchaseTokensWithBusd(tokens(300))
      ).to.be.revertedWith("Private Sale: Customer is not in Whitelist.");
      await expect(
        privateSaleOne.connect(carl).purchaseTokensWithBusd(tokens(300))
      ).to.be.revertedWith("Private Sale: Customer is not in Whitelist.");
      await expect(
        privateSaleOne.connect(deysi).purchaseTokensWithBusd(tokens(300))
      ).to.be.revertedWith("Private Sale: Customer is not in Whitelist.");
      await expect(
        privateSaleOne.connect(earl).purchaseTokensWithBusd(tokens(300))
      ).to.be.revertedWith("Private Sale: Customer is not in Whitelist.");
    });

    it("Customers purchasing more than 500 BUSD fails", async function () {
      await privateSaleOne.addToWhitelistBatch([
        alice.address,
        bob.address,
        carl.address,
      ]);
      await expect(
        privateSaleOne.connect(alice).purchaseTokensWithBusd(tokens(501))
      ).to.be.revertedWith(
        "Private Sale: 500 BUSD is the maximun amount of purchase."
      );
      await expect(
        privateSaleOne.connect(bob).purchaseTokensWithBusd(tokens(600))
      ).to.be.revertedWith(
        "Private Sale: 500 BUSD is the maximun amount of purchase."
      );
      await expect(
        privateSaleOne.connect(carl).purchaseTokensWithBusd(tokens(8000))
      ).to.be.revertedWith(
        "Private Sale: 500 BUSD is the maximun amount of purchase."
      );
    });

    it("Customer without enough balance should fail", async function () {
      await privateSaleOne.addToWhitelistBatch([earl.address, deysi.address]);
      await expect(
        privateSaleOne.connect(earl).purchaseTokensWithBusd(tokens(400))
      ).to.be.revertedWith(
        "Private Sale: Customer does not have enough balance."
      );
      await expect(
        privateSaleOne.connect(deysi).purchaseTokensWithBusd(tokens(500))
      ).to.be.revertedWith(
        "Private Sale: Customer does not have enough balance."
      );
    });
    it("Customers didn't give enough allowance", async function () {
      await pachaCuyBSC
        .connect(alice)
        .approve(privateSaleOne.address, tokens(100));
      await pachaCuyBSC
        .connect(bob)
        .approve(privateSaleOne.address, tokens(200));
      await pachaCuyBSC
        .connect(carl)
        .approve(privateSaleOne.address, tokens(10));

      await expect(
        privateSaleOne.connect(alice).purchaseTokensWithBusd(tokens(201))
      ).to.be.revertedWith("Private Sale: Customer didn't give allowance.");
      await expect(
        privateSaleOne.connect(bob).purchaseTokensWithBusd(tokens(201))
      ).to.be.revertedWith("Private Sale: Customer didn't give allowance.");
      await expect(
        privateSaleOne.connect(carl).purchaseTokensWithBusd(tokens(201))
      ).to.be.revertedWith("Private Sale: Customer didn't give allowance.");
    });

    it("Customers purchase pachacuys", async function () {
      await pachaCuyBSC
        .connect(alice)
        .approve(privateSaleOne.address, tokens(100));
      await pachaCuyBSC
        .connect(bob)
        .approve(privateSaleOne.address, tokens(501));
      await pachaCuyBSC
        .connect(carl)
        .approve(privateSaleOne.address, tokens(10));

      var busdSpent = tokens(90);
      var customer = alice;
      var prevBalance = await pachaCuyBSC.balanceOf(customer.address);
      await purchaseTokens(busdSpent, prevBalance, customer, customer.address);

      var busdSpent = tokens(500);
      var customer = bob;
      var prevBalance = await pachaCuyBSC.balanceOf(customer.address);
      await purchaseTokens(busdSpent, prevBalance, customer, customer.address);

      var busdSpent = tokens(1);
      await expect(
        privateSaleOne.connect(bob).purchaseTokensWithBusd(busdSpent)
      ).to.be.revertedWith(
        "Private Sale: 500 BUSD is the maximun amount of purchase."
      );
    });
  });

  describe("Tests upper limits", function () {
    it("Setting up new Private Sale SC", async function () {
      // Private Sale One
      PrivateSaleOne = await hre.ethers.getContractFactory("PrivateSaleOne");
      privateSaleOne = await upgrades.deployProxy(PrivateSaleOne, [
        pachaCuyBSC.address,
        custodianWallet.address,
        _exchangeRatePrivateSaleOne,
      ]);
      await privateSaleOne.deployed();
    });
    it("Purchasing above max", async function () {
      var totalAccounts = 30;
      var maxPerAccount = tokens(500);
      var randomWallets = [];

      // mint to 30 new accounts
      return;
      var provider = new ethers.providers.JsonRpcProvider(
        "http://127.0.0.1:8545/"
      );
      var mintPromises = new Array(totalAccounts).fill(null).map(function () {
        var randomWallet = ethers.Wallet.createRandom();
        randomWallets.push(provider.getSigner(randomWallet));
        return pachaCuyBSC.mint(randomWallet.address, maxPerAccount);
      });
      await Promise.all(mintPromises);

      // 30 accounts purchase 500 BUSD each
      console.log(randomWallets);
      return;
      var purchasePromises = randomWallets.map(function (customer) {
        var busdSpent = tokens(500);
        return privateSaleOne
          .connect(customer)
          .purchaseTokensWithBusd(busdSpent);
      });
      await Promise.all(purchasePromises);

      return;

      await pachaCuyBSC.mint(huidobro.address, tokens(1499411));
      await pachaCuyBSC
        .connect(huidobro)
        .approve(privateSaleOne.address, tokens(1499411));
      await privateSaleOne.addToWhitelistBatch([huidobro.address]);
      var busdSpent = tokens(1499410);
      var customer = huidobro;
      var prevBalance = await pachaCuyBSC.balanceOf(customer.address);
      await purchaseTokens(busdSpent, prevBalance, customer, customer.address);
    });
  });
});
