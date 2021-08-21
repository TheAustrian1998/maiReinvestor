const { expect } = require("chai");

describe("MaiReinvestor", function () {

    let QuickSwapV2Router02Addr = '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff';
    let UsdcSwapAddr = '0x947D711C25220d8301C087b25BA111FE8Cbf6672';
    let MaiStakingRewardsAddr = '0x574Fe4E8120C4Da1741b5Fd45584de7A5b521F0F';
    let UsdcAddr = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';
    let QiDaoAddr = '0x580A84C73811E1839F75d86d75d88cCa0c241fF4';
    let MaiAddr = '0xa3Fa99A148fA48D14Ed51d610c367C61876997F1';
    let pid = '2';

    let UsdcWhale = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';
    let UsdcWhaleSigner;

    before(async function(){
        this.accounts = await ethers.getSigners();

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [UsdcWhale],
        });

        UsdcWhaleSigner = await ethers.getSigner(UsdcWhale);

        //Deploy
        this.MaiReinvestor = await ethers.getContractFactory("MaiReinvestor");
        this.maiReinvestor = await this.MaiReinvestor.deploy(pid, QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr);
        await this.maiReinvestor.deployed();

        //Transfer some USDC to "this.accounts[0]"
        this.USDC = await ethers.getContractFactory("USDC");
        let usdcDecimals = await this.USDC.attach(UsdcAddr).connect(UsdcWhaleSigner).decimals();
        await this.USDC.attach(UsdcAddr).connect(UsdcWhaleSigner).transfer(this.accounts[0].address, ethers.utils.parseUnits("200000", String(usdcDecimals)));
    });

    it("Do nothing...", async function(){
        console.log("Nothing")
    });

});