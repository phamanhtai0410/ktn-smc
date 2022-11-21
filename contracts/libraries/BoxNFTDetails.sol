// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library BoxNFTDetails {
    using EnumerableSet for EnumerableSet.UintSet;

    struct BoxNFTDetail {
        uint256 id;
        uint256 index;    // index of id in user token array
        bool is_opened;   // false: still not open, true: opened
        address owner_by; // Owner token before on chain for marketplace.
        string tokenURI;  // Metadata Token
    }

    struct BoxConfigurations {
        string cid;
        uint256 defaultRarity;
        uint256 price;
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) dropRates;
        EnumerableSet.UintSet rarityList;
        EnumerableSet.UintSet meshIndexList;
        EnumerableSet.UintSet meshMaterialList;
    }
}