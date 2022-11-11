// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../libraries/CharacterTokenDetails.sol";


interface ICharacterToken is IERC721Upgradeable {
    /**
     *      @dev Funtion let MINTER_ROLE can mint token(s) for user
     */
    function mintOrderFromDaapCreator(
        CharacterTokenDetails.MintingOrder[] calldata _mintingOrders,
        address _to,
        string calldata _callbackData
    ) external;

    /**
     *      @dev Function allow to get current max rarity of current NFT collection
     */
    function getMaxRarityValue() external view returns (uint8);

    /**
     *      @dev Function returns tokenDetails by tokenId
     */
    function getTokenDetailsByID(uint256 _tokenId) external view returns(CharacterTokenDetails.TokenDetail memory);
}