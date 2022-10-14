// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTToken {
    function useNFTs(
        uint256[] memory _tokenIdsList, uint8 _rarity, uint8 _nftType
    ) external;

    function burn(uint256[] memory ids) external;
}
