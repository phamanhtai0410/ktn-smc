// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharacterToken {

    struct MintingOrder {
        uint8 rarity;
        string cid;
    }

    /**
     *      @dev Funtion let MINTER_ROLE can mint token(s) for user
     */
    function mint(MintingOrder[] calldata _mintingOrders, address _to, string calldata _orderId) external;

    /**
     *      @dev Function current list of rarity configed in contract NFT collection
     */
    function getCurrentRarityList() external view returns (uint8[] memory);

    /**
     *      @dev Function check the rarity is valid or not
     */
    function isValidRarity(uint8 _rarity) external view returns (bool);
}