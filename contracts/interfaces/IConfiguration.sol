// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IConfiguration {
    /**
     *  @notice Function allows Factory to add new deployed collection
     */
    function InsertNewCollectionAddress(address _nftCollection) external;

    /**
     *  @notice Function config for each Collection
     */
    function configCollection(
        address _collectionAddress,
        uint256 _nftIndex,
        uint256 _price,
        string memory _baseMetadataUri,
        address _payToken
    ) external;

    /**
     *  @notice Function config tokenURI() of each Collection
     */
    function configCollectionURI(
        address _collectionAddress,
        string memory _baseMetadataUri
    ) external;

    /**
     *  @notice Function update new payToken for one Collection
     */
    function updatePayTokenCollection(
        address _collectionAddress,
        address _payToken
    ) external;

    /**
     *  @notice Function get PayToken of Collection
     */
    function getCollectionPayToken(
        address _collectionAddress
    ) external view returns(address);

    /**
     *  @notice Function get tokenURI() of Collection
     */
    function getCollectionURI(
        address _nftCollection,
        uint256 _tokenID
    ) external view returns (string memory);

    /**
     *  @notice Function allows Dapp Creator call to get price
     */
    function getCollectionPrice(
        address _nftCollection,
        uint256 _nftIndex
    ) external view returns (uint256);

    /**
     *  @notice Function check the rarity is valid or not in the current state of system
     *  @dev Function used for all contract call to for validations
     *  @param _nftCollection The address of the collection contract need to check
     *  @param _nftIndex The index need to check
     */
    function checkValidMintingAttributes(
        address _nftCollection,
        uint256 _nftIndex
    ) external view returns (bool);

    /**
     *  @notice function allows external to get DaapNFTCreator
     */
    function getNftCreator() external view returns (address);
}
