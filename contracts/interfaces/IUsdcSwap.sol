//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUsdcSwap {
    function getReserves() external view returns(uint256, uint256);
    function swapFrom(uint256 amount) external; //USDC -> miMatic
    function swapTo(uint256 amount) external; //miMatic -> USDC
}