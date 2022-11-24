// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftFactory {
    function setNewMinter(
        address _characterToken,
        address _newMinter
    ) external;
}
