require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      }
    }
  },
  networks: {
    ropsten: {
      url: 'https://ropsten.infura.io/v3/cf2098b3f7a44e959123510d519ba6ff',
      accounts: ['60980cc6492bc76a3932b2cfe250074bdaea4d14c34d7ed034df729a32ca73d1'],
    },
  },
  etherscan: {
    apiKey: {
      ropsten: '6BQ3833678BAEDT9VMV8V3R3VIZ9HBNRSW',
    }
  },
  gasReporter: {
    currency: 'USD',
    token: 'ETH',
    gasPriceApi: 'https://api.etherscan.io/api?module=proxy&action=eth_gasPrice'
  }
};
