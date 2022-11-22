// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libraries/BoxNFTDetails.sol";

interface IBoxesConfigurations {
    /**
     *  @notice Function is used to get configurations informations of one box instant
     */
    function getBoxInfos(
        address _boxAddress
    ) external view returns(string memory, uint256, uint256);

    /**
     *  @notice Function allows Factory to add new deployed collection
     */
    function InsertNewCollectionAddress(address _nftCollection) external;

    /**
     *  @notice Fuction returns the cid of specificed BOX type
     *  @dev Function return for Nft Colleciton contract
     */
    function getCid() external view returns(string memory);

    function getDropRates(address _boxAddress) external view returns(BoxNFTDetails.DropRatesReturn[] memory);
}