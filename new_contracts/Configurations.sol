// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../libraries/CharacterTokenDetails.sol";

contract NftConfigurations is AccessControlUpgradeable {
    // Add the library methods
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using CharacterTokenDetails for CharacterTokenDetails.MintingOrder;

    // Event
    event AddNewBoxInstant(
        address boxContract,
        uint256[] rarityProportions,
        uint8 defaultRarity
    );

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // NFT Factory Address
    address public NFT_FACTORY;

    // Dapp Creator
    address public DAPP_CREATOR;

    // List of NFT collections
    EnumerableSet.AddressSet private nftCollectionsList;

    // List of NFT collections
    EnumerableSet.AddressSet private boxCollectionsList;

    // Price of one index in each collection
    mapping(address => mapping(uint256 => uint256)) public prices;

    // Price of boxes
    mapping(address => uint256) public boxPrices;

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
     *  @notice Function allows Factory to add new deployed box collection
     */
    function InsertNewBoxAddress(address _boxAddress) external onlyFromFactory {
        boxCollectionsList.add(_boxAddress);
    }

    /**
     *      Config price for each nftIndex of collection
     */
    function configCollectionPrice(
        address _collectionAddress,
        uint256 _nftIndex,
        uint256 _price
    ) external onlyFromFactory {
        require(
            nftCollectionsList.contains(_nftCollection),
            "Invalid NFT collection address"
        );
        prices[_collectionAddress][_nftIndex] = _price;
    }

    /**
     *      Config box's price
     */
    function configBoxPrice(
        address _boxAddress,
        uint256 _price
    ) external onlyFromFactory {}

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
     *  @notice Function allows Dapp Creator call to get box's price
     */
    function getBoxPrice(
        address _boxAddress
    ) external view onlyFromDappCreator returns (uint256) {
        require(
            boxCollectionsList.constains(_boxAddress) != 0,
            "Not-existing Box"
        );
        return prices[_nftCollection][_nftIndex];
    }

    /**
     *  @notice Function check the order attributes is valid or not in the current state of system
     *  @dev Function used for all contract call to for validations
     *  @param _nftCollection The address of the collection contract need to check
     *  @param _mintingOrder The order need to check
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
