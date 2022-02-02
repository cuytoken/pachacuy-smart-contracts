require("dotenv").config();

const hre = require("hardhat");
const { upgrades, ethers } = require("hardhat");
const { getImplementation, infoHelper } = require("../js-utils/helpers");

async function main() {
  // Private Sale
  var {
    _maxPrivateSaleOne,
    _maxPrivateSaleTwo,
    _busdToken,
    _walletPrivateSale,
    _exchangeRatePrivateSaleOne,
    _exchangeRatePrivateSaleTwo,
  } = infoHelper("TESTNET");
  const PrivateSale = await hre.ethers.getContractFactory("PrivateSale");
  const privateSale = await upgrades.deployProxy(PrivateSale, [
    _maxPrivateSaleOne,
    _maxPrivateSaleTwo,
    _busdToken,
    _walletPrivateSale,
    _exchangeRatePrivateSaleOne,
    _exchangeRatePrivateSaleTwo,
  ]);
  await privateSale.deployed();
  var implementationAddress = await getImplementation(privateSale.address);
  console.log("PrivateSale Proxy:", privateSale.address);
  console.log("PrivateSale Implementation:", implementationAddress);

  // PachaCuyBSC -> SwapCuyTokenForPachaCuy
  const PachaCuyBSC = await hre.ethers.getContractFactory("PachaCuyBSC");
  const pachaCuyBSC = await upgrades.deployProxy(PachaCuyBSC, []);
  await pachaCuyBSC.deployed();
  var implementationAddress = await getImplementation(pachaCuyBSC.address);
  console.log("PachaCuyBSC Proxy:", pachaCuyBSC.address);
  console.log("PachaCuyBSC Implementation:", implementationAddress);

  // SwapCuyTokenForPachaCuy
  var { _swapWallet, _exchangeRate } = infoHelper("TESTNET");
  const SwapCuyTokenForPachaCuy = await hre.ethers.getContractFactory(
    "SwapCuyTokenForPachaCuy"
  );
  const swapCuyTokenForPachaCuy = await upgrades.deployProxy(
    SwapCuyTokenForPachaCuy,
    [pachaCuyBSC.address, _swapWallet, _exchangeRate]
  );
  await swapCuyTokenForPachaCuy.deployed();
  var implementationAddress = await getImplementation(
    swapCuyTokenForPachaCuy.address
  );
  console.log(
    "SwapCuyTokenForPachaCuy Proxy:",
    swapCuyTokenForPachaCuy.address
  );
  console.log("SwapCuyTokenForPachaCuy Implementation:", implementationAddress);

  // Public Sale
  var { _maxPublicSale, _walletPublicSale, _busdToken } = infoHelper("TESTNET");
  const PublicSale = await hre.ethers.getContractFactory("PublicSale");
  const publicSale = await upgrades.deployProxy(PublicSale, [
    _maxPublicSale,
    _walletPublicSale,
    _busdToken,
  ]);
  await publicSale.deployed();
  var implementationAddress = await getImplementation(publicSale.address);
  console.log("PublicSale Proxy:", publicSale.address);
  console.log("PublicSale Implementation:", implementationAddress);

  // Vesting
  var { _vestingPeriods, _gapBetweenVestingPeriod } = infoHelper("TESTNET");
  const Vesting = await hre.ethers.getContractFactory("Vesting");
  const vesting = await upgrades.deployProxy(Vesting, [
    _vestingPeriods,
    _gapBetweenVestingPeriod,
  ]);
  await vesting.deployed();
  var implementationAddress = await getImplementation(vesting.address);
  console.log("Vesting Proxy:", vesting.address);
  console.log("Vesting Implementation:", implementationAddress);

  // Airdrop
  const Airdrop = await hre.ethers.getContractFactory("Airdrop");
  const airdrop = await upgrades.deployProxy(Airdrop, []);
  await airdrop.deployed();
  var implementationAddress = await getImplementation(airdrop.address);
  console.log("Airdrop Proxy:", airdrop.address);
  console.log("Airdrop Implementation:", implementationAddress);

  // PoolDynamics
  const PoolDynamics = await hre.ethers.getContractFactory("PoolDynamics");
  const poolDynamics = await upgrades.deployProxy(PoolDynamics, []);
  await poolDynamics.deployed();
  var implementationAddress = await getImplementation(poolDynamics.address);
  console.log("PoolDynamics Proxy:", poolDynamics.address);
  console.log("PoolDynamics Implementation:", implementationAddress);

  // PhaseTwoAndX
  var { _capLimitPhaseTwo, _capLimitPhaseX } = infoHelper("TESTNET");
  const PhaseTwoAndX = await hre.ethers.getContractFactory("PhaseTwoAndX");
  const phaseTwoAndX = await upgrades.deployProxy(PhaseTwoAndX, [
    _capLimitPhaseTwo,
    _capLimitPhaseX,
  ]);
  await phaseTwoAndX.deployed();
  var implementationAddress = await getImplementation(phaseTwoAndX.address);
  console.log("PhaseTwoAndX Proxy:", phaseTwoAndX.address);
  console.log("PhaseTwoAndX Implementation:", implementationAddress);

  // Pachacuy
  var { _liquidityPoolWallet } = infoHelper("TESTNET");
  const PachaCuy = await hre.ethers.getContractFactory("PachaCuy");
  const pachaCuy = await upgrades.deployProxy(PachaCuy, [
    privateSale.address,
    swapCuyTokenForPachaCuy.address,
    publicSale.address,
    vesting.address,
    airdrop.address,
    _liquidityPoolWallet,
    poolDynamics.address,
    phaseTwoAndX.address,
  ]);
  await pachaCuy.deployed();
  var implementationAddress = await getImplementation(pachaCuy.address);
  console.log("PachaCuy Token Proxy:", pachaCuy.address);
  console.log("PachaCuy Token Implementation:", implementationAddress);

  // Final setting
  var { admin } = infoHelper("TESTNET");
  await privateSale.setPachaCuyAddress(pachaCuy.address);
  await privateSale.grantRole(admin, process.env.WALLET_FOR_FUNDS);

  await swapCuyTokenForPachaCuy.setPachaCuyAddress(pachaCuy.address);
  await swapCuyTokenForPachaCuy.grantRole(admin, process.env.WALLET_FOR_FUNDS);

  await publicSale.setPachaCuyAddress(pachaCuy.address);
  await publicSale.grantRole(admin, process.env.WALLET_FOR_FUNDS);

  await vesting.setPachaCuyAddress(pachaCuy.address);
  await vesting.grantRole(admin, process.env.WALLET_FOR_FUNDS);

  await airdrop.setPachaCuyAddress(pachaCuy.address);
  await airdrop.grantRole(admin, process.env.WALLET_FOR_FUNDS);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
