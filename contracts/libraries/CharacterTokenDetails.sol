// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CharacterTokenDetails {
    struct TokenDetail {
        uint8 rarity;
        string tokenURI;
        bool isUsed;
    }

    struct MintingOrder {
        uint8 rarity;
        string cid;
    }

    struct ReturnMintingOrder {
        uint256 tokenId;
        uint8 rarity;
        string cid;
    }
}