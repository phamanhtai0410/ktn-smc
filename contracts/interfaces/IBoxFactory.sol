// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBoxFactory {
    function getBoxesConfigurations() external returns(address);
    function getBoxCreator() external returns(address);
    function NftCollection(address _boxAddress) external view returns(address);
}
