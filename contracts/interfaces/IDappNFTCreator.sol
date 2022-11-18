// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDappNFTCreator {

    /**
     *  @notice Set price for each rarity type
     */
    function upgradeNewNftType(uint8[] memory _maxRarityList) external;

    /**
     *  @notice Set price for upgrade existing nft type
     */
    function upgradeExisitingNftType(uint8 _exisitingNftType, uint8 _upgradeMaxRarity) external;

    function addNewCollection()
}
