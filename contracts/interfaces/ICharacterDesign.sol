// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharacterDesign {
    
    struct RarityDetail {
        string name;
        uint256 totalSupply;
    }

    function getTotalSupply() external view returns (uint256);

    function getRarityDetails(uint8 _rarityId) external returns (RarityDetail calldata);
    
    function lastRarityId() external returns (uint8);
    
    function createNewDesign(uint256 _tokenId) external;

}
