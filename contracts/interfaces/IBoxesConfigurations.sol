// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libraries/BoxNFTDetails.sol";

interface IBoxesConfigurations {
    /**
     *  @notice Function is used to get configurations informations of one box instant
     */
    function getBoxInfos(
        address _boxAddress
    ) external view returns(BoxNFTDetails.BoxConfigurations memory);
}