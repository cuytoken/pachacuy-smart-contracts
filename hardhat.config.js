require("dotenv").config();

require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

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
    localhost: {
      url: "http://127.0.0.1:8545/",
      timeout: 800000,
      gas: "auto",
      gasPrice: "auto",
    },
    rinkeby: {
      url: process.env.RINKEBY_TESNET_URL,
      accounts: [process.env.ADMIN_ACCOUNT_PRIVATE_KEY],
      timeout: 800000,
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
    bsctestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [process.env.ADMIN_ACCOUNT_PRIVATE_KEY],
      gas: "auto",
      gasPrice: "auto",
      timeout: 0,
    },
    bscmainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gas: "auto",
      gasPrice: "auto",
      accounts: [process.env.BSCMAINNET_ADMIN_ACCOUNT_PRIVATE_KEY],
      timeout: 800000,
    },
  },
  etherscan: { apiKey: process.env.PACHACUY_BSCSCAN_API_KEY },
};
