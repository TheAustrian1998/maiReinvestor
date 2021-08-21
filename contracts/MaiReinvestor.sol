//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUsdcSwap.sol";
import "./interfaces/IMaiStakingRewards.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

contract MaiReinvestor is Ownable {

    uint256 public pid;

    IUniswapV2Router02 public QuickSwapV2Router02;
    IUsdcSwap public UsdcSwap;
    IMaiStakingRewards public MaiStakingRewards;

    IERC20 public Usdc;
    IERC20 public QiDao;
    IERC20 public Mai;
    IERC20 public LPToken;

    constructor(
        uint256 _pid,
        address _QuickSwapV2Router02Addr,
        address _UsdcSwapAddr,
        address _MaiStakingRewardsAddr,
        address _UsdcAddr,
        address _QiDaoAddr,
        address _MaiAddr,
        address _LPToken
    ) {
        //Set vars
        pid = _pid; //Pool Id

        QuickSwapV2Router02 = IUniswapV2Router02(_QuickSwapV2Router02Addr);
        UsdcSwap = IUsdcSwap(_UsdcSwapAddr);
        MaiStakingRewards = IMaiStakingRewards(_MaiStakingRewardsAddr);

        Usdc = IERC20(_UsdcAddr);
        QiDao = IERC20(_QiDaoAddr); //Governance token
        Mai = IERC20(_MaiAddr); //Stable
        LPToken = IERC20(_LPToken);

        //Submit approvals
        Usdc.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Usdc.approve(_UsdcSwapAddr, type(uint256).max);
        QiDao.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Mai.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        LPToken.approve(_MaiStakingRewardsAddr, type(uint256).max);
    }

    function _addLiquidity(uint256 deadline) internal returns (uint256) {

        uint256 MaiBalanceToAdd = Mai.balanceOf(address(this));
        uint256 UsdcBalanceToAdd = Usdc.balanceOf(address(this));
        address tokenA = address(Usdc);
        address tokenB = address(Mai);

        //Provide liquidity
        (, , uint256 liquidity) = QuickSwapV2Router02.addLiquidity(
            tokenA,
            tokenB,
            UsdcBalanceToAdd,
            MaiBalanceToAdd,
            UsdcBalanceToAdd - ((UsdcBalanceToAdd * 2) / 100),
            MaiBalanceToAdd - ((MaiBalanceToAdd * 2) / 100),
            address(this),
            deadline
        );

        return liquidity;
    }

    function _swapQiForUsdc(uint256 QiDaoBalance, uint256 deadline) internal {
        address[] memory path = new address[](2);
        path[0] = address(QiDao);
        path[1] = address(Usdc);

        uint256[] memory amountsOut = QuickSwapV2Router02.getAmountsOut(
            QiDaoBalance,
            path
        );

        uint256 minAmount = amountsOut[1] - ((amountsOut[1] * 1) / 100); // 1% slippage
        address receiver = address(this);

        QuickSwapV2Router02.swapExactTokensForTokens(
            QiDaoBalance,
            minAmount,
            path,
            receiver,
            deadline
        );
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
            //Swap all QiDao for Usdc
            _swapQiForUsdc(QiDaoBalance, deadline);
        }

        //Check if Usdc balance > 0
        uint256 UsdcBalance = Usdc.balanceOf(address(this));
        if (UsdcBalance > 0) {

            //Swap half of Usdc to Mai
            UsdcSwap.swapFrom(UsdcBalance / 2);

            //Add liquidity
            uint256 liquidity = _addLiquidity(deadline);
            
            //Deposit on Stake (Harvest if possible)
            MaiStakingRewards.deposit(pid, liquidity);
        }
    }

}
