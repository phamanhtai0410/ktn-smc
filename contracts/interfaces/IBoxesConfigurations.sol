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

    /**
     *  @notice Function allows to get dropRates array for one specificed box
     */
    function getDropRates(address _boxAddress) external view returns(BoxNFTDetails.DropRatesReturn[] memory);

    /**
     *  @notice Function allows Factory contract to config one box
     */
    function configOne(
        address _boxCollection,
        string memory _cid,
        uint256 _price,
        uint256 _defaultIndex
    ) external;

    /**
     *  @notice Funtion allows Factory to config Drop rates of each elements in Box
     */
    function configDroppedRate(
        address _boxAddress,
        uint256 _rarity,
        uint256 _meshIndex,
        uint256 _meshMaterial,
        uint256 _proportion
    ) external;

    /**
     *  @notice function returns current nftCollection for the Box Configurations
     */
    function getNftCollection() external view returns(address);
}