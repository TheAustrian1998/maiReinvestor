require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");

let { alchemyUrl, etherscanApi, privateKey } = require("./secrets.json");

module.exports = {
  solidity: "0.8.0",
  networks: {
    hardhat: {
      forking: {
        url: alchemyUrl,
        timeout: 200000
      }
    },
    polygon: {
      url: alchemyUrl,
      accounts: [privateKey]
    }
  },
  etherscan: {
    apiKey: etherscanApi
  }
};