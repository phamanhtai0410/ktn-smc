// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NftConfigurations is
    AccessControlUpgradeable
{
    // Add the library methods
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Event
    event AddNewBoxInstant(address boxContract, uint256[] rarityProportions, uint8 defaultRarity);

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // NFT Factory Address
    address public NFT_FACTORY;

    // List of NFT collections
    EnumerableSet.AddressSet private nftCollectionsList;

    // List of rarity
    mapping(address => EnumerableSet.UintSet) private rarityList;

    // List active mesh index each rarity
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) private meshList;

    // Price of one mesh index
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public pricePerMesh;
    
    // List active mesh material index each meshIndex in one rarity
    mapping(address => mapping(uint256 => mapping(uint256 => EnumerableSet.UintSet))) private meshMaterialList;

    // Mapping Nft Type ID with cids
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => string)))) public cid;

    // modifier to check from Factory or not
    modifier onlyFromFactory() {
        require(msg.sender == NFT_FACTORY, "Can only call from Factory contract");
        _;
    }

    constructor (address _nftFactory) {
        NFT_FACTORY = _nftFactory;
    }

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    /**
     *  @notice Function allows Factory to add new deployed collection
     */
    function InsertNewCollectionAddress(address _nftCollection) external onlyFromFactory {
        nftCollectionsList.add(_nftCollection);
    }

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
    ) external onlyRole(UPGRADER_ROLE) {
        require(
            nftCollectionsList.contains(_nftCollection),
            "Invalid NFT collection address"
        );
        if (!rarityList[_nftCollection].contains(_rarity)) {
            rarityList[_nftCollection].add(_rarity);
        }
        if (!meshList[_nftCollection][_rarity].contains(_meshIndex)) {
            meshList[_nftCollection][_rarity].add(_meshIndex);
            pricePerMesh[_nftCollection][_rarity][_meshIndex] = _price;
        }
        if (!meshMaterialList[_nftCollection][_rarity][_meshIndex].contains(_meshMaterial)) {
            meshMaterialList[_nftCollection][_rarity][_meshIndex].add(_meshMaterial);
            cid[_nftCollection][_rarity][_meshIndex][_meshMaterial] = _cid;
        }
    }

    /**
     *  @notice Fuction returns the cid of specificed NFT type with attributes: rarity. meshIndex, meshMaterial,...etc
     *  @dev Function return for Nft Colleciton contract
     *  @param _rarity The rarity needs to trigger
     *  @param _meshIndex The mesh Index need to trigger
     *  @param _meshMaterial 
     */

    
}