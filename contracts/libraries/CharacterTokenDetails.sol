// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CharacterTokenDetails {
    struct TokenDetail {
        MintingOrder mintingOrder;
        string tokenURI;
    }

    struct MintingOrder {
        uint256 rarity;
        uint256 meshIndex;
        uint256 meshMaterial;
    }

    struct ReturnMintingOrder {
        uint256 tokenId;
        MintingOrder mintingOrder;
    }
}
