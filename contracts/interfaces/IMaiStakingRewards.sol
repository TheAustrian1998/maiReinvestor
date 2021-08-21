//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMaiStakingRewards {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function deposited(uint256 _pid, address _user) external view returns (uint256);
    function pending(uint256 _pid, address _user) external view returns (uint256);
    function emergencyWithdraw(uint256 _pid) external;
}