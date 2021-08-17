//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUsdcSwap.sol";
import "./IMaiStakingRewards.sol";
import "./IUniswapV2Router02.sol";

contract MaiReinvestor is Ownable {

    IUniswapV2Router02 public QuickSwapV2Router02;
    IUsdcSwap public UsdcSwap;
    IERC20 public USDC;
    IERC20 public miMatic;

    constructor(){

    }

    function deposit(uint amount) public onlyOwner {
        //Deposits USDC
        USDC.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint amount) public onlyOwner{
        //Withdraw USDC
        USDC.transfer(msg.sender, amount);
    }

    function reinvest() public {
        //Reinvest all tokens in contract

        //Swap half of USDC to miMatic
        uint USDCBalance = USDC.balanceOf(address(this));
        UsdcSwap.swapFrom(USDCBalance);

        //Provide liquidity
    }
}