// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../CharacterToken.sol";

interface ICharacterToken {

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
}