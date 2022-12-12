// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import "src/naive-receiver/FlashLoanReceiver.sol";
import "src/naive-receiver/NaiveReceiverLenderPool.sol";
import "src/naive-receiver/AttackerContract.sol";


/// https://book.getfoundry.sh/forge/writing-tests
contract NaiveReceiver is Test {


    uint256 internal constant ETHER_IN_POOL = 1000 ether;
    uint256 internal constant ETHER_IN_RECEIVER = 10 ether;

    FlashLoanReceiver internal flashLoanReceiver;
    NaiveReceiverLenderPool internal naiveReceiverLenderPool;
  
    address internal deployer;
    address internal attacker;
    address internal someUser;

    function setUp() public {
        // solhint-disable-previous-line no-empty-blocks
        deployer = vm.addr(1);
        vm.label(deployer, "deployer");
        attacker = vm.addr(2);
        vm.label(attacker, "attacker");
        someUser = vm.addr(3);
        vm.label(someUser, "someUser");

        naiveReceiverLenderPool = new NaiveReceiverLenderPool();
        vm.label(address(naiveReceiverLenderPool), "lenderPool");
        vm.deal(address(naiveReceiverLenderPool), ETHER_IN_POOL);

        assertEq(address(naiveReceiverLenderPool).balance, ETHER_IN_POOL);
        assertEq(naiveReceiverLenderPool.fixedFee(), 1 ether);

        flashLoanReceiver = new FlashLoanReceiver(payable(naiveReceiverLenderPool));
        vm.label(address(flashLoanReceiver), "flashLoanReceiver");
        vm.deal(address(flashLoanReceiver), ETHER_IN_RECEIVER);

        assertEq(address(flashLoanReceiver).balance, ETHER_IN_RECEIVER);

    }


    /// @dev Run Forge with `-vvvv` to see console logs.
    function testExploit() public {

        vm.startPrank(attacker);
        AttackerContract attack = new AttackerContract(naiveReceiverLenderPool, payable(flashLoanReceiver));
        vm.stopPrank();
        validate();
    }

    function validate() internal {

        assertEq(address(flashLoanReceiver).balance, 0 ether);
        assertEq(address(naiveReceiverLenderPool).balance, ETHER_IN_POOL + ETHER_IN_RECEIVER);

    }
}