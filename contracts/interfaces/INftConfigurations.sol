// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftConfigurations  {
    /**
     *  @notice Function allows Factory to add new deployed collection
     */
    function InsertNewCollectionAddress(address _nftCollection) external;
    
     /**
     *  @notice Function allows ADMIN to add new configurations for one completed NFT type 
     * (include rarity, mesh, mesh material, price, cid)
     *  @dev Function will add new attributes to list attrs if is not existed
     *  @param _nftCollection The address of current configed NFT
     *  @param _rarity The rarity index of that wants to config
     *  @param _meshIndex The meshIndex of current configurations
     *  @param _price The price of the current configed mesh
     *  @param _meshMaterial The index of material (color,..etc)
     *  @param _cid The cid from ipfs for each type of NFT
     */
    function configNewOne(
        address _nftCollection,
        uint256 _rarity,
        uint256 _meshIndex,
        uint256 _price,
        uint256 _meshMaterial,
        string memory _cid
    ) external;

    /**
     *  @notice Fuction returns the cid of specificed NFT type with attributes: rarity. meshIndex, meshMaterial,...etc
     *  @dev Function return for Nft Colleciton contract
     *  @param _rarity The rarity needs to trigger
     *  @param _meshIndex The mesh Index need to trigger
     *  @param _meshMaterial The mesh material of nft need to trigger
     */
    function getCid(
        uint256 _rarity,
        uint256 _meshIndex,
        uint256 _meshMaterial
    ) external;
}