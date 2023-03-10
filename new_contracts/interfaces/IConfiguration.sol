// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IConfiguration {
    /**
     *  @notice Function allows Factory to add new deployed collection
     */
    function InsertNewCollectionAddress(address _nftCollection) external;

    /**
     *  @notice Function allows Factory to add new deployed collection
     */
    function InsertNewBoxAddress(address _boxAddress) external;

    /**
     *  @notice Function allows Dapp Creator call to get price
     */
    function getPrice(
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
