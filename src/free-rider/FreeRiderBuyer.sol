// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "forge-std/Test.sol";

/**
 * @title FreeRiderBuyer
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FreeRiderBuyer is ReentrancyGuard, IERC721Receiver, Test {
    using Address for address payable;

    address private immutable partner;
    IERC721 private immutable nft;
    uint256 private constant JOB_PAYOUT = 45 ether;
    uint256 private received;

    constructor(address _partner, address _nft) payable {
        require(msg.value == JOB_PAYOUT);
        partner = _partner;
        nft = IERC721(_nft);
        IERC721(_nft).setApprovalForAll(msg.sender, true);
    }

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(address, address, uint256 _tokenId, bytes memory)
        external
        override
        nonReentrant
        returns (bytes4)
    {
        require(msg.sender == address(nft), "message sender incorrect");
        require(tx.origin == partner, "tx origin is not partner");
        require(_tokenId >= 0 && _tokenId <= 5, "incorrect token id");
        require(nft.ownerOf(_tokenId) == address(this), "not owner of nft");
        console2.log("received token %s", _tokenId);
        received++;
        if (received == 6) {
            payable(partner).sendValue(JOB_PAYOUT);
        }
        console2.log("sent payout");
        return IERC721Receiver.onERC721Received.selector;
    }
}
