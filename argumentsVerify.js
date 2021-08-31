const { QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, pid, UsdcWhale, LPToken, QiDaoWhale } = require("./addressesRegistry.json");

/*npx hardhat verify --constructor-args argumentsVerify.js DEPLOYED_CONTRACT_ADDRESS --network polygon */

module.exports = [
    pid, QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, LPToken
];