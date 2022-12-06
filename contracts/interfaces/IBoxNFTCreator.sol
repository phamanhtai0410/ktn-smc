// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBoxNFTCreator  {
    /**
     *      @dev Function get boxPrice
     */
    function getBoxPrice(address _boxAddress) external view returns (uint256);
}