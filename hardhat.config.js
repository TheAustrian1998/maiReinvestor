require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");


let { alchemyUrl, etherscanApi, mnemonic } = require("./secrets.json");

module.exports = {
  solidity: "0.8.0",
  networks: {
    hardhat: {
      forking: {
        url: alchemyUrl,
      }
    },
    polygon: {
      url: alchemyUrl,
      accounts: mnemonic
    }
  },
  etherscan: {
    apiKey: etherscanApi
  }
};