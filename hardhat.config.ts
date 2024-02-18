require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

const { projectId, mnemonic } = require('./secrets.json');

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    arbitrum_sepolia: {
      url: "https://arb-sepolia.g.alchemy.com/v2/<Alchemy_Key>",
      accounts: { mnemonic: mnemonic },
      gasPrice: 0,
      gas: 8000000,
      timeout: 1000000
    }
  },
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  etherscan: {
    apiKey: {
      sepolia: "<Etherscan_ApiKey>"
    },
    customChains: [
      {
        network: "sepolia",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://api-sepolia.arbiscan.io"
        }
      }
    ]
  }
};

