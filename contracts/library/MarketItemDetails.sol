// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MarketItems {
    struct MarketItemDetails {
        uint256 tokenId; // token id
        uint8 itemType; // 1: character, 2: skin, 3: items,...
        uint8 rarity;   // rarity of market item [common, rare, mythical, legendary, immotal]
        bool isOnMarket; // false: still private, true: on market
        bool isUse; // false: not use, true: used
        address ownerBy;  // Owner token before on chain for marketplace.
    }
}
