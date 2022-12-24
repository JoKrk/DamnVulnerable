// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {FreeRiderBuyer} from "src/free-rider/FreeRiderBuyer.sol";
import {FreeRiderNFTMarketplace} from "src/free-rider/FreeRiderNFTMarketplace.sol";


contract AttackerContract {
    IUniswapV2Pair internal uniswapV2Pair;
    FreeRiderBuyer internal buyer;
    FreeRiderNFTMarketplace internal marketPlace;
    address payable public owner;

   constructor(address pairAddr, address partnerAddr, address marketPlaceAddr) {
        uniswapV2Pair = IUniswapV2Pair(pairAddr);
        buyer = FreeRiderBuyer(partnerAddr);
        marketPlace = FreeRiderNFTMarketplace(marketPlaceAddr);
        owner = payable(msg.sender);



    }


    function snatchNFT() external {
        marketPlace
    }
    
}