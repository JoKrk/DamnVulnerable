// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { PRBTest } from "@prb/test/PRBTest.sol";
import "forge-std/Test.sol";
import {UnstoppableLender} from "src/unstoppable/UnstoppableLender.sol";
import {ReceiverUnstoppable} from "src/unstoppable/ReceiverUnstoppable.sol";


/// https://book.getfoundry.sh/forge/writing-tests
contract Unstoppable is PRBTest, Test {


    address private deployer;
    address private attacker;
    address private someUser;
    
    function setUp() public {
        // solhint-disable-previous-line no-empty-blocks
        deployer = vm.addr(1);
        attacker = vm.addr(2);
        someUser = vm.addr(3);

        
    }

    /// @dev Run Forge with `-vvvv` to see console logs.
    function testExample() public {
        console2.log("Hello World");
        assertTrue(true);
    }
}