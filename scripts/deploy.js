const { ethers } = require("hardhat");
const { QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, pid, LPToken } = require("../addressesRegistry.json");

async function main() {
    await hre.run("compile");

    const MaiReinvestor = await ethers.getContractFactory("MaiReinvestor");
    const maiReinvestor = await MaiReinvestor.deploy(pid, QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, LPToken);
    await maiReinvestor.deployed();

    console.log("Deployed to:", maiReinvestor.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });