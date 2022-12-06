// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftFactory {
    function setNewMinter(
        address _characterToken,
        address _newMinter
    ) external;

    function getCurrentDappCreatorAddress() external view returns (address);

    /**
     *  @notice Function allows to get the current Nft Configurations
     */
    function getCurrentNftConfigurations() external view returns (address);
}
