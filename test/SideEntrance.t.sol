// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import "src/side-entrance/SideEntranceLenderPool.sol";
import "src/side-entrance/SideAttacker.sol";


/// https://book.getfoundry.sh/forge/writing-tests
contract SideEntrance is Test {

    uint256 public attackerInitialEthBalance;
    uint256 internal constant ETHER_IN_POOL  = 1000 ether;
    SideEntranceLenderPool  internal sideEntranceLenderPool;

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

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;
    }


    /// @dev Run Forge with `-vvvv` to see console logs.
    function testExploit() public {

        vm.startPrank(attacker);
        SideAttacker sideAttacker = new SideAttacker(address(sideEntranceLenderPool));
        sideAttacker.flashLoan();
        sideAttacker.withdrawPrize();
        vm.stopPrank();
        validate();
    }

    function validate() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}