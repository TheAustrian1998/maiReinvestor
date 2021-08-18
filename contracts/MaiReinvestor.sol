//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUsdcSwap.sol";
import "./interfaces/IMaiStakingRewards.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract MaiReinvestor is Ownable {
    address public QuickSwapV2Router02Addr;
    address public UsdcSwapAddr;
    address public MaiStakingRewardsAddr;
    address public UsdcAddr;
    address public MiMaticAddr;
    address public MaiAddr;

    uint256 public pid;

    IUniswapV2Router02 public QuickSwapV2Router02 = IUniswapV2Router02(QuickSwapV2Router02Addr);
    IUsdcSwap public UsdcSwap = IUsdcSwap(UsdcSwapAddr);
    IMaiStakingRewards public MaiStakingRewards = IMaiStakingRewards(MaiStakingRewardsAddr);
    IERC20 public Usdc = IERC20(UsdcAddr);
    IERC20 public MiMatic = IERC20(MiMaticAddr);
    IERC20 public Mai = IERC20(MaiAddr);

    constructor(
        uint256 _pid,
        address _QuickSwapV2Router02Addr,
        address _UsdcSwapAddr,
        address _MaiStakingRewardsAddr,
        address _UsdcAddr,
        address _miMaticAddr,
        address _MaiAddr
    ) {
        //Set vars
        pid = _pid; //Pool Id
        QuickSwapV2Router02Addr = _QuickSwapV2Router02Addr;
        UsdcSwapAddr = _UsdcSwapAddr;
        MaiStakingRewardsAddr = _MaiStakingRewardsAddr;
        UsdcAddr = _UsdcAddr;
        MiMaticAddr = _miMaticAddr;
        MaiAddr = _MaiAddr;

        //Submit approvals
        Usdc.approve(QuickSwapV2Router02Addr, type(uint).max);
        Usdc.approve(UsdcSwapAddr, type(uint).max);
        MiMatic.approve(QuickSwapV2Router02Addr, type(uint).max);
        Mai.approve(QuickSwapV2Router02Addr, type(uint).max);
    }

    function deposit(uint256 amount) public onlyOwner {
        //Deposits Usdc
        Usdc.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        //Withdraw Usdc
        Usdc.transfer(msg.sender, amount);
    }

    function reinvest() public onlyOwner {
        //Reinvest all tokens in contract
        uint256 deadline = block.timestamp + 5 minutes;

        //Check if Mai balance > 0
        uint256 MaiBalance = Mai.balanceOf(address(this));
        if (MaiBalance > 0) {
            //Swap all for Usdc
            address[] memory path = new address[](2);
            path[0] = MaiAddr;
            path[1] = UsdcAddr;
            uint256[] memory amountsOut = QuickSwapV2Router02.getAmountsOut(
                MaiBalance,
                path
            );
            uint256 minAmount = amountsOut[1] - ((amountsOut[1] * 1) / 100); // 1% slippage
            QuickSwapV2Router02.swapExactTokensForTokens(
                MaiBalance,
                minAmount,
                path,
                address(this),
                deadline
            );
        }

        //Check if Usdc balance > 0
        uint256 UsdcBalance = Usdc.balanceOf(address(this));
        uint256 MiMaticBalance = MiMatic.balanceOf(address(this));
        if (UsdcBalance > 0) {
            //Swap half of Usdc to MiMatic
            UsdcSwap.swapFrom(UsdcBalance);

            //Provide liquidity
            (, , uint256 liquidity) = QuickSwapV2Router02.addLiquidity(
                UsdcAddr,
                MiMaticAddr,
                UsdcBalance,
                MiMaticBalance,
                UsdcBalance - ((UsdcBalance * 1) / 100),
                MiMaticBalance - ((MiMaticBalance * 1) / 100),
                address(this),
                deadline
            );

            //Deposit on Stake (Harvest if possible)
            MaiStakingRewards.deposit(pid, liquidity);
        }
    }
}
