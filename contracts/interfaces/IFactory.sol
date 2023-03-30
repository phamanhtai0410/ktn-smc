// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    function setNewMinter(address _characterToken, address _newMinter) external;

    /**
     *  @notice Function allows to get the current Nft Configurations
     */
    function getCurrentConfiguration() external view returns (address);
    function getCurrentDappCreatorAddress() external view returns (address);
}
