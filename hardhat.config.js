require("@nomiclabs/hardhat-waffle");
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