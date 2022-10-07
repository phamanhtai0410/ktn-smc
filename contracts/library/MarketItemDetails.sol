// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MarketItems {


    struct MarketItemDetails {
        uint256 tokenId; // token id
        uint256 price; // price in USDT or Token
        uint256 itemType; // 0: character, 1: skin, 2: items
        bool isOnMarket; // false: still private, true: on market
        address ownerBy;  // Owner token before on chain for marketplace.
    }
}
