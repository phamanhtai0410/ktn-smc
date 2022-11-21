// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/ICharacterToken.sol";
import "../libraries/BoxNFTDetails.sol";


contract BoxesConfigurations is
    AccessControlUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // Event
    event AddNewBoxInstant(address boxContract, uint256[] rarityProportions, uint8 defaultRarity);

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // List of NFT collections
    EnumerableSet.AddressSet private boxCollectionList;

    // Box Factory Address
    address public BOX_FACTORY;

    // Address of NFT collection
    ICharacterToken public NFT_COLLECTION;

    // Address of Box Creator
    address public BOX_CREATOR;

    // Mapping Box Type with cids (NFT => (Box => Cid))
    mapping(address => mapping(address => string)) private cid;

    // Store boxInstant's Instant
    mapping(address => mapping(address => BoxNFTDetails.BoxConfigurations)) public boxInfos;
    
    // Box price
    mapping(address => mapping(address => uint256)) public boxPrices;



    constructor (address _boxFactory, address _nftColelction, address _boxCreator) {
        NFT_COLLECTION = ICharacterToken(_nftColelction);
        BOX_FACTORY = _boxFactory;
        BOX_CREATOR = _boxCreator;
    }

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    // modifier to check from Factory or not
    modifier onlyFromFactory() {
        require(msg.sender == BOX_FACTORY, "Can only call from Factory contract");
        _;
    }

    modifier onlyFromValidBoxCollection() {
        require(boxCollectionList.contains(msg.sender), "Can only call from valid box contract");
        _;
    }

    modifier onlyFromBoxCreator() {
        require(msg.sender == BOX_CREATOR, "Can only call from Box Creator");
        _;
    }

    /**
    *  @notice Function allows Factory to add new deployed BOX.
    */
    function InsertNewCollectionAddress(address _boxNFT) external onlyFromFactory {
        boxCollectionList.add(_boxNFT);
    }

    /**
     * @notice Adds new Box Instant.
     * @dev Function is invoked by UPGRADER to add new Box Instant type of current NFT Collection
     * @param _boxInstantContract The address of the new deployed Box Instant
     * @param _proportions The proportions of drop NFT each rarity
     **/
    function addNewBoxInstant(
        address _boxInstantContract,
        uint256[] memory _proportions,
        uint8 _defaultRarity
    ) external onlyRole(UPGRADER_ROLE) {
        require(NFT_COLLECTION.getMaxRarityValue() == uint8(_proportions.length), "Invalid the length of proportions of each rarity");
        boxInfos[_boxInstantContract].rarityProportions = _proportions;
        boxInfos[_boxInstantContract].defaultRarity = _defaultRarity;
        emit AddNewBoxInstant(_boxInstantContract, _proportions, _defaultRarity);
    }

    function configOne(
        address _boxCollection,
        string memory _cid,
        uint256 _price
    ) external onlyFromFactory {
        require(
            boxCollectionList.contains(_boxCollection),
            "Invalid BOX collection address"
        );
        cid[address(NFT_COLLECTION)][_boxCollection] = _cid;
        boxPrices[address(NFT_COLLECTION)][_boxCollection] = _price;
    }

    /**
     *  @notice Function returns the proportions of each rarity of the specificed box Instant and boxType- index of box
     * @param _boxAddress The address of box Instant that wants to check
     */
    function getBoxInfos(
        address _boxAddress
    ) public view returns(BoxNFTDetails.BoxConfigurations memory){
        return boxInfos[address(NFT_COLLECTION)][_boxAddress];
    }

    /**
     *  @notice Fuction returns the cid of specificed NFT type 
     *  @dev Function return for Box Colleciton contract
     */
    function getCid() external onlyFromValidBoxCollection view returns(string memory) {
        return cid[address(NFT_COLLECTION)][msg.sender];
    }
}