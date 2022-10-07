// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTToken {
    function useNFTs(
        address to,
        uint256 count,
        uint8 rarity
    ) external;

    function burn(uint256[] memory ids) external;
}
