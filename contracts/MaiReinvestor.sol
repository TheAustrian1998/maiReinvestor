//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUsdcSwap.sol";
import "./interfaces/IMaiStakingRewards.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "hardhat/console.sol";

contract MaiReinvestor is Ownable {

    uint256 public pid;

    IUniswapV2Router02 public QuickSwapV2Router02;
    IUsdcSwap public UsdcSwap;
    IMaiStakingRewards public MaiStakingRewards;

    IERC20 public Usdc;
    IERC20 public QiDao;
    IERC20 public Mai;
    IUniswapV2Pair public LPToken;

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
        LPToken = IUniswapV2Pair(_LPToken);

        //Submit approvals
        Usdc.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Usdc.approve(_UsdcSwapAddr, type(uint256).max);
        QiDao.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Mai.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Mai.approve(_UsdcSwapAddr, type(uint256).max);
        LPToken.approve(_MaiStakingRewardsAddr, type(uint256).max);
        LPToken.approve(_QuickSwapV2Router02Addr, type(uint256).max);
    }

    function getDeadline() public view returns (uint256) {
        return block.timestamp + 5 minutes;
    }

    function getDeposited() public view returns (uint256) {
        return MaiStakingRewards.deposited(pid, address(this));
    }

    function getPending() public view returns (uint256) {
        return MaiStakingRewards.pending(pid, address(this));
    }

    function _getLiquidityAmounts() public view returns (uint256, uint256) {
        //This function determines the quantity of each token corresponds to this contract, based on LP
        (uint112 reserve0, uint112 reserve1, ) = LPToken.getReserves();
        uint256 totalSupply = LPToken.totalSupply();
        uint256 poolPerc = (LPToken.balanceOf(address(this)) * 100 / totalSupply);
        return (reserve0 * poolPerc / 100, reserve1 * poolPerc / 100);
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

    function _removeLiquidity(uint256 deadline) internal {
        uint256 liquidity = LPToken.balanceOf(address(this));
        address tokenA = address(Usdc);
        address tokenB = address(Mai);

        (uint256 amountAMin, uint256 amountBMin) = _getLiquidityAmounts();

        QuickSwapV2Router02.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, address(this), deadline);
    }

    function _swapQiForUsdc(uint256 deadline) internal {
        uint256 QiDaoBalance = QiDao.balanceOf(address(this));

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

    function reinvest(uint256 deadline) public onlyOwner {
        //Reinvest all tokens in contract

        //Harvest
        MaiStakingRewards.deposit(pid, 0);

        //Check if QiDao balance > 0
        uint256 QiDaoBalance = QiDao.balanceOf(address(this));
        if (QiDaoBalance > 0) {

            //Swap all QiDao for Usdc
            _swapQiForUsdc(deadline);
        }

        //Check if Usdc balance > 0
        uint256 UsdcBalance = Usdc.balanceOf(address(this));
        if (UsdcBalance > 0) {

            //Swap half of Usdc to Mai
            UsdcSwap.swapFrom(UsdcBalance / 2);
            
            //Add liquidity
            uint256 liquidity = _addLiquidity(deadline);
            
            //Deposit on Stake
            MaiStakingRewards.deposit(pid, liquidity);
        }
    }

    function closePosition(uint256 deadline) public onlyOwner {
        //Redeem all positions, send all tokens to owner

        //Remove liquidity from Stake and harvest
        uint256 depositedAmount = getDeposited();
        MaiStakingRewards.withdraw(pid, depositedAmount);

        //Swap all QiDao to USDC
        _swapQiForUsdc(deadline);

        //Remove liquidity from Quickswap
        _removeLiquidity(deadline);

        //Swap all Mai to USDC
        uint256 MaiBalance = Mai.balanceOf(address(this));
        UsdcSwap.swapTo(MaiBalance);

        //Send all USDC to owner
        Usdc.transfer(owner(), Usdc.balanceOf(address(this)));
    }

}
