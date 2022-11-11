// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTToken {
    function useNFTs(
        uint256[] memory _tokenIdsList
    ) external;

    function burn(uint256[] memory ids) external;

    function openBoxes(uint256[] calldata tokenIds_) external;
}
