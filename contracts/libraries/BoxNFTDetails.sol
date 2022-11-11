// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BoxNFTDetails {
    struct BoxNFTDetail {
        uint256 id;
        uint256 index;    // index of id in user token array
        uint256 price;    // price
        bool on_market;   // false: still private, true: on market
        bool is_opened;   // false: still not open, true: opened
        address owner_by; // Owner token before on chain for marketplace.
    }
}