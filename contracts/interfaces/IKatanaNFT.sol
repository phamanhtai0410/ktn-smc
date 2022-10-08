// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKatanaNFT is IERC721{
    /**
    * @dev Returns the remaining rarity of current tokenId
    */
    function getItemInfoById(uint256 tokenId) external view returns(uint8 itemType, uint8 rarity);
}
