// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../libraries/BoxNFTDetails.sol";


interface IMysteryBoxNFT is IERC721Upgradeable {
    /**
     *      @dev Funtion let MINTER_ROLE can mint token(s) for user
     */
    function mintBoxFromDaapCreator(
        uint256 _count,
        bool _isWhitelistMint,
        address _to,
        string calldata _callbackData
    ) external;
}