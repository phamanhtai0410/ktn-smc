// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CharacterToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ICharacterToken is IERC721Upgradeable {

    /**
     *      @dev Funtion let MINTER_ROLE can mint token(s) for user
     */
    function mint(
        CharacterToken.MintingOrder[] calldata _mintingOrders,
        address _to,
        bytes calldata _callbackData
    ) external;

    /**
     *      @dev Function allow to get current max of nftType
     */
    function getMaxRarityValue(uint8 _nftType) external view returns (uint8);

    /**
     *      @dev Function allow to get max rarity of current nftType
     */
    function getMaxNftType() external view returns(uint8);

    /**
     *      @dev Function returns tokenDetails by tokenId
     */
    function getTokenDetailsByID(uint256 _tokenId) external view returns(CharacterToken.TokenDetail memory);
}