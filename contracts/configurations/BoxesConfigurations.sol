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
    using EnumerableSet for EnumerableSet.UintSet;
    using BoxNFTDetails for BoxNFTDetails.BoxConfigurations;
    using BoxNFTDetails for BoxNFTDetails.Attributes;
    using BoxNFTDetails for BoxNFTDetails.DropRatesReturn;

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

    // Box's Informations: mapping box address => BoxConfigurations
    mapping(address => BoxNFTDetails.BoxConfigurations) private boxInfos;

    constructor (address _boxFactory, address _nftCollection, address _boxCreator) {
        NFT_COLLECTION = ICharacterToken(_nftCollection);
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
     *  @notice Funtions that allow to config proportions of each elements in box
     *  @param _boxAddress The address of the triggered box
     *  @param _rarity The rarity
     *  @param _meshIndex The mesh ID
     *  @param _meshMaterial The mesh material ID
     *  @param _proportion The rate of dropping
     */
    function configDroppedRate(
        address _boxAddress,
        uint256 _rarity,
        uint256 _meshIndex,
        uint256 _meshMaterial,
        uint256 _proportion
    ) external onlyFromFactory {
        boxInfos[_boxAddress].dropRates[_rarity][_meshIndex][_meshMaterial] = _proportion;
        if (!boxInfos[_boxAddress].rarityList.contains(_rarity)) {
            boxInfos[_boxAddress].rarityList.add(_rarity);
        }
        if (!boxInfos[_boxAddress].meshIndexList.contains(_meshIndex)) {
            boxInfos[_boxAddress].meshIndexList.add(_meshIndex);
        }
        if (!boxInfos[_boxAddress].meshMaterialList.contains(_meshMaterial)) {
            boxInfos[_boxAddress].meshMaterialList.add(_meshMaterial);
        }
    }


    /**
     *  @notice Function allows to config cid nnd price for each Box from Box Factory
     *  @param _boxCollection The address of box contract instant
     *  @param _cid The cid that wants to config to the box
     *  @param _price The price that wants to config to box
     *  @param _defaultIndex The default of rarity that wants to config
     */
    function configOne(
        address _boxCollection,
        string memory _cid,
        uint256 _price,
        uint256 _defaultIndex
    ) external onlyFromFactory {
        require(
            boxCollectionList.contains(_boxCollection),
            "Invalid BOX collection address"
        );
        boxInfos[_boxCollection].cid = _cid;
        boxInfos[_boxCollection].price = _price;
        boxInfos[_boxCollection].defaultIndex = _defaultIndex;

    }

    /**
     *  @notice Function returns the proportions of each rarity of the specificed box Instant and boxType- index of box
     *  @param _boxAddress The address of box Instant that wants to check
     */
    function getBoxInfos(
        address _boxAddress
    ) public view returns(string memory, uint256, uint256){
        return (
            boxInfos[_boxAddress].cid,
            boxInfos[_boxAddress].defaultIndex,
            boxInfos[_boxAddress].price
        );
    }

    /**
     *  @notice Function allows to get table of dropRates
     */
    function getDropRates(address _boxAddress) external view returns(BoxNFTDetails.DropRatesReturn[] memory) {
        BoxNFTDetails.DropRatesReturn[] memory dropRateReturns = new BoxNFTDetails.DropRatesReturn[](
            boxInfos[_boxAddress].rarityList.length() * boxInfos[_boxAddress].meshIndexList.length() * boxInfos[_boxAddress].meshMaterialList.length()
        );
        uint256 index;
        for (uint256 i=0; i < boxInfos[_boxAddress].rarityList.length(); i++) {
            for (uint256 j=0; j < boxInfos[_boxAddress].meshIndexList.length(); j++) {

                for (uint256 k=0; k < boxInfos[_boxAddress].meshMaterialList.length(); k++) {
                    BoxNFTDetails.Attributes memory _attrs;

                    _attrs.rarity = boxInfos[_boxAddress].rarityList.at(i);
                    _attrs.meshIndex = boxInfos[_boxAddress].meshIndexList.at(j);
                    _attrs.meshMaterialIndex = boxInfos[_boxAddress].meshMaterialList.at(k);

                    dropRateReturns[index].attributes = _attrs;
                    dropRateReturns[index].dropRate = boxInfos[
                        _boxAddress
                    ].dropRates[
                        _attrs.rarity
                    ][
                        _attrs.meshIndex
                    ][
                        _attrs.meshMaterialIndex
                    ];
                    index+=1;
                }
            }
        }
        return dropRateReturns;
    }

    /**
     *  @notice Fuction returns the cid of specificed NFT type
     *  @dev Function return for Box Colleciton contract
     */
    function getCid() external onlyFromValidBoxCollection view returns(string memory) {
        return boxInfos[msg.sender].cid;
    }
}
