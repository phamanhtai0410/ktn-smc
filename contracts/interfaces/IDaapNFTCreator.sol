// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDaapNFTCreator {

    /**
     *  @notice Set price for each rarity type
     */
    function upgradeNewNftType(uint8 _maxNftType, uint8[] memory _maxRarityList) external;

    /**
     *  @notice Set price for upgrade existing nft type
     */
    function upgradeExisitingNftType(uint8 _exisitingNftType, uint8 _upgradeMaxRarity) external;
}