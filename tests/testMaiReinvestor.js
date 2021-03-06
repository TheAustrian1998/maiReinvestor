const { expect } = require("chai");
const { QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, pid, UsdcWhale, LPToken, QiDaoWhale } = require("../addressesRegistry.json");

describe("MaiReinvestor", function () {

    let UsdcWhaleSigner;
    let QiDaoWhaleSigner;
    let usdcDecimals;

    before(async function () {
        this.timeout( 60000 );
        [deployerSigner] = await ethers.getSigners();

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [UsdcWhale],
        });
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [QiDaoWhale],
        });
        await network.provider.send("hardhat_setBalance", [
            QiDaoWhale,
            "0x3635C9ADC5DEA00000",
        ]);

        UsdcWhaleSigner = await ethers.getSigner(UsdcWhale);
        QiDaoWhaleSigner = await ethers.getSigner(QiDaoWhale);

        //Deploy
        this.MaiReinvestor = await ethers.getContractFactory("MaiReinvestor");
        this.maiReinvestor = await this.MaiReinvestor.deploy(pid, QuickSwapV2Router02Addr, UsdcSwapAddr, MaiStakingRewardsAddr, UsdcAddr, QiDaoAddr, MaiAddr, LPToken);
        await this.maiReinvestor.deployed();

        //GenericERC20
        this.GenericERC20 = await ethers.getContractFactory("GenericERC20");

        //Transfer some USDC to "deployerSigner"
        usdcDecimals = await this.GenericERC20.attach(UsdcAddr).connect(UsdcWhaleSigner).decimals();
        await this.GenericERC20.attach(UsdcAddr).connect(UsdcWhaleSigner).transfer(deployerSigner.address, ethers.utils.parseUnits("200000", usdcDecimals));

        //Transfer some QiDao to "maiReinvestor" contract
        await this.GenericERC20.attach(QiDaoAddr).connect(QiDaoWhaleSigner).transfer(this.maiReinvestor.address, ethers.utils.parseUnits("2000"));

    });

    it("Should 'deposit()' successfully...", async function () {
        this.timeout( 60000 );
        let balanceToDeposit = ethers.utils.parseUnits("50000", usdcDecimals);
        await this.GenericERC20.attach(UsdcAddr).approve(this.maiReinvestor.address, balanceToDeposit);
        await this.maiReinvestor.deposit(balanceToDeposit);
        expect(await this.GenericERC20.attach(UsdcAddr).balanceOf(this.maiReinvestor.address)).equal(balanceToDeposit);
    });

    it("Should 'reinvest()' successfully...", async function () {
        this.timeout( 60000 );
        let deadline = await this.maiReinvestor.getDeadline();
        await this.maiReinvestor.reinvest(deadline);
        expect(await this.GenericERC20.attach(QiDaoAddr).balanceOf(this.maiReinvestor.address)).equal(0);
        expect(await this.GenericERC20.attach(LPToken).balanceOf(this.maiReinvestor.address)).equal(0);
    });

    it("Should 'closePosition()' successfully...", async function () {
        this.timeout( 60000 );
        let deadline = await this.maiReinvestor.getDeadline();
        await this.maiReinvestor.closePosition(deadline);
        expect(await this.GenericERC20.attach(QiDaoAddr).balanceOf(this.maiReinvestor.address)).equal(0);
        expect(await this.GenericERC20.attach(LPToken).balanceOf(this.maiReinvestor.address)).equal(0);
        expect(await this.GenericERC20.attach(MaiAddr).balanceOf(this.maiReinvestor.address)).equal(0);
        expect(await this.GenericERC20.attach(UsdcAddr).balanceOf(this.maiReinvestor.address)).equal(0);
    });

});