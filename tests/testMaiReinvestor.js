const { expect } = require("chai");
const { QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, pid, UsdcWhale, LPToken } = require("../addressesRegistry.json");

describe("MaiReinvestor", function () {

    let UsdcWhaleSigner;
    let usdcDecimals;

    before(async function () {
        this.accounts = await ethers.getSigners();

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [UsdcWhale],
        });

        UsdcWhaleSigner = await ethers.getSigner(UsdcWhale);

        //Deploy
        this.MaiReinvestor = await ethers.getContractFactory("MaiReinvestor");
        this.maiReinvestor = await this.MaiReinvestor.deploy(pid, QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, LPToken);
        await this.maiReinvestor.deployed();

        //Transfer some USDC to "this.accounts[0]"
        this.USDC = await ethers.getContractFactory("USDC");
        usdcDecimals = await this.USDC.attach(UsdcAddr).connect(UsdcWhaleSigner).decimals();
        await this.USDC.attach(UsdcAddr).connect(UsdcWhaleSigner).transfer(this.accounts[0].address, ethers.utils.parseUnits("200000", String(usdcDecimals)));
    });

    it("Should deposit successfully...", async function () {
        let balanceToDeposit = ethers.utils.parseUnits("50000", String(usdcDecimals));
        await this.USDC.attach(UsdcAddr).approve(this.maiReinvestor.address, balanceToDeposit);
        await this.maiReinvestor.deposit(balanceToDeposit);
        expect(await this.USDC.attach(UsdcAddr).balanceOf(this.maiReinvestor.address)).equal(balanceToDeposit);
    });

    it("Should 'reinvest()' successfully...", async function(){
        await this.maiReinvestor.reinvest();
    });

    it.skip("Should withdraw successfully...", async function(){

    });

});