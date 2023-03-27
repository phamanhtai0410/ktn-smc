// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Configurations is AccessControlUpgradeable {
    // Add the library methods
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;


    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // NFT Factory Address
    address public NFT_FACTORY;

    // Config URI NFT 
    // NFT address => uri
    mapping(address => string) public uriNFTs;
    
    // Dapp Creator
    address public DAPP_CREATOR;

    // List of NFT collections
    EnumerableSet.AddressSet private nftCollectionsList;

    // Price of one index in each collection
    mapping(address => mapping(uint256 => uint256)) public prices;


    // modifier to check from Factory or not
    modifier onlyFromFactory() {
        require(
            msg.sender == NFT_FACTORY,
            "Can only call from Factory contract"
        );
        _;
    }

    // Modifier just accept call from dappCreator
    modifier onlyFromDappCreator() {
        require(
            msg.sender == DAPP_CREATOR,
            "Can only call from Dapp Creator contract"
        );
        _;
    }

    modifier onlyFromValidNftCollection() {
        require(
            nftCollectionsList.contains(msg.sender),
            "Invalid NftCollection"
        );
        _;
    }

    constructor(address _nftFactory, address _dappCreator) {
        NFT_FACTORY = _nftFactory;
        DAPP_CREATOR = _dappCreator;
    }

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    /**
     *  @notice Function allows Factory to add new deployed collection
     */
    function InsertNewCollectionAddress(
        address _nftCollection
    ) external onlyFromFactory {
        nftCollectionsList.add(_nftCollection);
    }

    /**
     *      Config for each nftIndex of collection
     */
    function configCollection(
        address _collectionAddress,
        uint256 _nftIndex,
        uint256 _price,
        string memory _baseMetadataUri

    ) external onlyFromFactory {
        require(
            nftCollectionsList.contains(_collectionAddress),
            "Invalid NFT collection address"
        );
        prices[_collectionAddress][_nftIndex] = _price;
        uriNFTs[_collectionAddress] = _baseMetadataUri;
    }

    /**
     *      Config for each tokenURI() of collection
     */
    function configCollectionURI(
        address _collectionAddress,
        string memory _baseMetadataUri
    ) external onlyFromFactory  {
        require(
            nftCollectionsList.contains(_collectionAddress),
            "Invalid NFT collection address"
        );
        uriNFTs[_collectionAddress] = _baseMetadataUri;
    }

    /**
     *      get tokenURI() of collection
     */
    function getCollectionURI(
        address _collectionAddress,
        uint256 _tokenId
    ) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    uriNFTs[_collectionAddress],
                    "/",
                    Strings.toHexString(uint256(uint160(_collectionAddress)), 20),
                    "/",
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }


    /**
     *  @notice Function allows Dapp Creator call to get collection's price
     */
    function getCollectionPrice(
        address _nftCollection,
        uint256 _nftIndex
    ) external view onlyFromDappCreator returns (uint256) {
        require(
            prices[_nftCollection][_nftIndex] != 0,
            "Not-existing NFT index"
        );
        return prices[_nftCollection][_nftIndex];
    }

    /**
     *  @notice Function check the order attributes is valid or not in the current state of system
     *  @dev Function used for all contract call to for validations
     *  @param _nftCollection The address of the collection contract need to check
     *  @param _nftIndex The order need to check
     */
    function checkValidMintingAttributes(
        address _nftCollection,
        uint256 _nftIndex
    ) external view returns (bool) {
        return prices[_nftCollection][_nftIndex] != 0;
    }

    /// Getters
    /**
     *  @notice function allows external to get DaapNFTCreator
     */
    function getNftCreator() external view returns (address) {
        return DAPP_CREATOR;
    }
}
