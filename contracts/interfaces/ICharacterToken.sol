// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharacterToken {
    function openBox(
        address to,
        uint256 count,
        uint256 boxType,
        uint256 faction
    ) external;

    function burn(uint256[] memory ids) external;
}
