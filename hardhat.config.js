require("dotenv").config();

require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-erc1820");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 20,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {},
    localhost: {
      url: "HTTP://127.0.0.1:7545",
      timeout: 800000,
      gas: "auto",
      gasPrice: "auto",
    },
    rinkeby: {
      url: process.env.RINKEBY_TESNET_URL,
      accounts: [process.env.ADMIN_ACCOUNT_PRIVATE_KEY],
      timeout: 0,
      gas: "auto",
      gasPrice: "auto",
    },
    ropsten: {
      url: process.env.ROPSTEN_TESNET_URL,
      accounts: [process.env.ADMIN_ACCOUNT_PRIVATE_KEY],
      timeout: 800000,
      gas: "auto",
      gasPrice: "auto",
    },
    polygon: {
      url: process.env.ALCHEMY_POLYGON_URL,
      accounts: [process.env.MAINNET_ADMIN_ACCOUNT_PRIVATE_KEY],
      timeout: 0,
      gas: "auto",
      gasPrice: "auto",
    },
    matic: {
      // url: process.env.ALCHEMY_MUMBAI_TESTNET_URL,
      url: "https://matic-mumbai.chainstacklabs.com",
      accounts: [process.env.ADMIN_ACCOUNT_PRIVATE_KEY],
      timeout: 0,
      gas: "auto",
      gasPrice: "auto",
    },
    bsctestnet: {
      url: "https://data-seed-prebsc-2-s1.binance.org:8545/",
      // url: "https://apis-sj.ankr.com/5fd853a4c9234579bcddd80bd1bce488/09fcd9583de58e60f81cc495f9be95bb/binance/full/test",
      chainId: 97,
      accounts: [process.env.ADMIN_ACCOUNT_PRIVATE_KEY],
      gas: "auto",
      gasPrice: 35000000000,
      timeout: 0,
    },
    bscmainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gas: "auto",
      gasPrice: "auto",
      accounts: [process.env.MAINNET_ADMIN_ACCOUNT_PRIVATE_KEY],
      timeout: 800000,
    },
  },
  // etherscan: { apiKey: process.env.PACHACUY_BSCSCAN_API_KEY },
  etherscan: { apiKey: process.env.PACHACUY_POLYGON_SCAN },
  // etherscan: { apiKey: process.env.PACHACUY_ETHERSCAN },
};
