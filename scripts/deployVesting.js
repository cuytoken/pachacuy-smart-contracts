const { upgrades, ethers, hardhatArguments } = require("hardhat");
const hre = require("hardhat");

const {
  safeAwait,
  getImplementation,
  executeSet,
} = require("../js-utils/helpers");
var pe = ethers.utils.parseEther;

// const NETWORK = "BSCNET";
var gcf = hre.ethers.getContractFactory;
var dp = upgrades.deployProxy;
var bn = ethers.BigNumber.from;
async function main() {
  var [owner] = await ethers.getSigners();
  if (process.env.HARDHAT_NETWORK) upgrades.silenceWarnings();

  const Vesting = await gcf("Vesting");
  const vesting = await dp(Vesting, [], {
    kind: "uups",
  });
  await vesting.deployed();
  console.log("Vesting Proxy:", vesting.address);
  var vestingImp = await getImplementation(vesting);
  console.log("Vesting Imp:", vestingImp);

  /**
   * Pachacuy Token PCUY
   * 1. Gather all operators and pass it to the initialize
   */
  var PachaCuyToken, pachaCuyToken, pachacuyTokenImp;
  if (process.env.HARDHAT_NETWORK) {
    PachaCuyToken = await gcf("PachaCuyToken");
    pachaCuyToken = await dp(
      PachaCuyToken,
      [
        vesting.address,
        owner.address,
        owner.address,
        owner.address,
        owner.address,
        [owner.address],
      ],
      {
        kind: "uups",
      }
    );
    await pachaCuyToken.deployed();
    console.log("PachaCuyToken Proxy:", pachaCuyToken.address);
    pachacuyTokenImp = await getImplementation(pachaCuyToken);
    console.log("PachaCuyToken Imp:", pachacuyTokenImp);
  }

  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  console.log("Finish Setting up Smart Contracts");
  console.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
  var r = [
    "HOLDER_CUY_TOKEN",
    "PRIVATE_SALE_1",
    "PRIVATE_SALE_2",
    "AIRDROP",
    "PACHACUY_TEAM",
    "PARTNER_ADVISOR",
    "MARKETING",
  ];

  var c = [
    pe("1"),
    pe("1.5"),
    pe("0.6"),
    pe("1.2"),
    pe("12"),
    pe("10"),
    pe("10"),
  ];
  // Vesting
  var ves = vesting;
  var pcuyA = pachaCuyToken.address;
  await executeSet(ves, "settingVestingStateStructs", [r, c], "ves 001");
  await executeSet(ves, "setPachaCuyAddress", [pcuyA], "ves 002");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
