// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ICollection is IERC721Upgradeable {
    /**
     *      @dev Funtion let MINTER_ROLE can mint token(s) for user
     */
    function mintOrderFromDaapCreator(
        uint256[] calldata _mintingOrders,
        bool _isWhitelistMint,
        address _to,
        string calldata _callbackData
    ) external;

    /** Function returns last tokenId at the moment */
    function lastId() external view returns (uint256);

    /** Mint token with rarities from dev purpose */
    function mintOrderForDev(
        uint256[] calldata _mintingOrders,
        address _to,
        bytes calldata _callbackData
    ) external;

    /**
     *      @notice Funtion switch mode of minting
     */
    function updateDisableMinting(bool _newState) external;

    /**
     *      @dev Function allow ADMIN to set free transfer flag
     */
    function switchFreeTransferMode() external;

    /**
     *      @dev Set whitelis
     */
    function setWhiteList(address _to) external;

    function mintFromBoxOpening(
        uint256[] memory _randomNumbers,
        address _to
    ) external;
}
