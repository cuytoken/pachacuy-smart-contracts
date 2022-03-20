const { upgrades } = require("hardhat");
const hre = require("hardhat");

const { getImplementation, infoHelper } = require("../js-utils/helpers");

// const NETWORK = "BSCNET";
const NETWORK = "BSCTESTNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;

async function main() {
  var [owner] = await ethers.getSigners();
  console.log("Deployer (Ethereum):", owner.address);

  // ERC-721
  var { _busdToken, _tokenName, _tokenSymbol, _maxSupply, _nftCurrentPrice } =
    infoHelper(NETWORK);
  const PachacuyNftCollection = await gcf("PachacuyNftCollection");
  const pachacuyNftCollection = await dp(
    PachacuyNftCollection,
    [
      _tokenName,
      _tokenSymbol,
      _maxSupply,
      _nftCurrentPrice,
      _busdToken,
      process.env.WALLET_FOR_FUNDS,
    ],
    {
      kind: "uups",
    }
  );
  var tx = await pachacuyNftCollection.deployed();
  console.log("PachacuyNftCollection Proxy:", pachacuyNftCollection.address);
  var pcuynftImp = await getImplementation(pachacuyNftCollection);
  console.log("PachacuyNftCollection Imp:", pcuynftImp);

  try {
    await hre.run("verify:verify", {
      address: pcuynftImp,
      constructorArguments: [],
    });
  } catch (error) {
    console.error("Error veryfing - Binary Search", error);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
