require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");

let { alchemyUrl } = require("./secrets.json");

module.exports = {
  solidity: "0.8.0",
  networks: {
    hardhat: {
      forking: {
        url: alchemyUrl,
      }
    }
  }
};