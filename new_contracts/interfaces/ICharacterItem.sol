// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";


interface ICharacterItem is IERC721Upgradeable {
    /**
     *  @dev Functions allow to mint a character item NFT from a character token
     */
    function createNewItem(uint256 _tokenId) external;
}