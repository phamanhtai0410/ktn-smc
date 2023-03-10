// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BoxDetails {
    struct BoxDetail {
        uint256 id;
        uint256 index; // index of id in user token array
        bool is_opened; // false: still not open, true: opened
        address owner_by; // Owner token before on chain for marketplace.
    }
}
