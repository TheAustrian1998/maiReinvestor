const { QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, pid, LPToken } = require("../addressesRegistry.json");

async function main() {
    //Compile
    await hre.run("compile");

    //Deploy
    const MaiReinvestor = await ethers.getContractFactory("MaiReinvestor");
    const maiReinvestor = await MaiReinvestor.deploy(pid, QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, LPToken);
    await maiReinvestor.deployed();
    console.log("Deployed to:", maiReinvestor.address);

    //Verify
    /*await hre.run("verify:verify", {
        address: maiReinvestor.address,
        constructorArguments: [pid, QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, LPToken],
    });*/
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });