const { expect } = require("chai");

describe("MaiReinvestor", function () {
    it("Should connect and should balance successful...", async function(){
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [""],
        });

        let signer = await ethers.getSigner("");
        console.log(ethers.utils.formatUnits(await signer.getBalance()));
    });
});