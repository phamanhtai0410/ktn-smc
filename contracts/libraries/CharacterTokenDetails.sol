// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CharacterTokenDetails {
    struct TokenDetail {
        uint8 rarity;
        uint8 nftType;
        string tokenURI;
        bool isUsed;
    }

    struct MintingOrder {
        uint8 rarity;
        string cid;
        uint8 nftType;
    }

    struct ReturnMintingOrder {
        uint256 tokenId;
        uint8 rarity;
        string cid;
        uint8 nftType;
    }
}