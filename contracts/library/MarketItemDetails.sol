// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MarketItems {
    struct MarketItemDetails {
        uint256 tokenId; // token id
        uint256 price; // price in USDT or Token
        uint8 itemType; // 1: character, 2: skin, 3: items,...
        uint8 rarity;   // rarity of market item []
        bool isOnMarket; // false: still private, true: on market
        address ownerBy;  // Owner token before on chain for marketplace.
    }
}
