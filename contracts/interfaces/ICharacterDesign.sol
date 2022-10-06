// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharacterDesign {
    function getTokenLimit() external view returns (uint256);

    function getMintCost(uint256 boxType) external view returns (uint256);

    function createRandomToken(
        uint256 id,
        uint256 rarity,
        uint256 eggType,
        uint256 faction
    ) external returns (uint256 nextSeed);

    function _transferable(
        address from,
        address to,
        uint256 id
    ) external view returns (bool);

}
