//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUsdcSwap.sol";
import "./interfaces/IMaiStakingRewards.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract MaiReinvestor is Ownable {
    uint256 public pid;

    IUniswapV2Router02 public QuickSwapV2Router02;
    IUsdcSwap public UsdcSwap;
    IMaiStakingRewards public MaiStakingRewards;

    IERC20 public Usdc;
    IERC20 public QiDao;
    IERC20 public Mai;

    constructor(
        uint256 _pid,
        address _QuickSwapV2Router02Addr,
        address _UsdcSwapAddr,
        address _MaiStakingRewardsAddr,
        address _UsdcAddr,
        address _QiDaoAddr,
        address _MaiAddr
    ) {
        //Set vars
        pid = _pid; //Pool Id
        QuickSwapV2Router02 = IUniswapV2Router02(_QuickSwapV2Router02Addr);
        UsdcSwap = IUsdcSwap(_UsdcSwapAddr);
        MaiStakingRewards = IMaiStakingRewards(_MaiStakingRewardsAddr);
        Usdc = IERC20(_UsdcAddr);
        QiDao = IERC20(_QiDaoAddr); //Governance token
        Mai = IERC20(_MaiAddr); //Stable

        //Submit approvals
        Usdc.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Usdc.approve(_UsdcSwapAddr, type(uint256).max);
        QiDao.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Mai.approve(_QuickSwapV2Router02Addr, type(uint256).max);
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

        //Check if QiDao balance > 0
        uint256 QiDaoBalance = QiDao.balanceOf(address(this));
        if (QiDaoBalance > 0) {
            //Swap all for Usdc
            address[] memory path = new address[](2);
            path[0] = address(QiDao);
            path[1] = address(Usdc);
            uint256[] memory amountsOut = QuickSwapV2Router02.getAmountsOut(
                QiDaoBalance,
                path
            );
            uint256 minAmount = amountsOut[1] - ((amountsOut[1] * 1) / 100); // 1% slippage
            QuickSwapV2Router02.swapExactTokensForTokens(
                QiDaoBalance,
                minAmount,
                path,
                address(this),
                deadline
            );
        }

        //Check if Usdc balance > 0
        uint256 UsdcBalance = Usdc.balanceOf(address(this));
        if (UsdcBalance > 0) {
            //Swap half of Usdc to Mai
            UsdcSwap.swapFrom(UsdcBalance / 2);

            uint256 MaiBalance = Mai.balanceOf(address(this));
            UsdcBalance = Usdc.balanceOf(address(this));

            //Provide liquidity
            (, , uint256 liquidity) = QuickSwapV2Router02.addLiquidity(
                address(Usdc),
                address(Mai),
                UsdcBalance,
                MaiBalance,
                UsdcBalance - ((UsdcBalance * 1) / 100),
                MaiBalance - ((MaiBalance * 1) / 100),
                address(this),
                deadline
            );

            //Deposit on Stake (Harvest if possible)
            MaiStakingRewards.deposit(pid, liquidity);
        }
    }
}
