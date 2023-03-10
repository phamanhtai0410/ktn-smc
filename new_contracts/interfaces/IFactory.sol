// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    function setNewMinter(address _characterToken, address _newMinter) external;

    /**
     *  @notice Function allows to get the current Nft Configurations
     */
    function getCurrentConfiguration() external view returns (address);
    function getCurrentDappCreatorAddress() external view returns (address);

    function getOpeningCollectionOfBox(address _boxAddress) external returns(address);

    function checkIsValidBox(address _boxAddress) external returns (bool);
}
