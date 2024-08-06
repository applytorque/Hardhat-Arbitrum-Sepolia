require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

const { privateKey } = require('./secrets.json');

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    sepolia: {
      url: "https://sepolia.infura.io/v3/d7ec99ee4a3b49639b8c3aed20cf0eaf",
      accounts: [privateKey],
      gasPrice: 20000000000, // 20 Gwei
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
    apiKey: "CIXEDP4EIYUTKX692Y445DYZ6GQSNPYBIE"
  }
};
