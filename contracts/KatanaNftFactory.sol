// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import "./CharacterToken.sol";
import "./DaapNFTCreator.sol";


contract KatanaNftFactory is AccessControl {

    event CreateNftCollection(
        address nftAddress,
        uint8 maxRarityValue,
        address dappCreatorAddress
    );
    event SetDappCreator(address newDappCreator);
    event SetNewMinterRole(address nftCollection, address newMinter);
    event AddNewNftRariies(address nftColelction, uint256[] addingPrices, uint8 oldMaxRarity, uint8 newMaxRarity);
    event UpdateNewPrice(address nftCollection, uint8 rarity, uint256 newPrice);
    event UpdateCidOfExistingRarity(address nftCollection, uint8 rarity, string newCid);

    bytes32 public constant IMPLEMENTATION_ROLE = keccak256("IMPLEMENTATION_ROLE");

    // Katana Collection Address list
    address[] public nftCollectionsAddress;

    // Checker isInListCollections
    mapping(address => bool) public isInListCollections;

    // Wrapper Creator address: using for calling from dapp
    address public dappCreatorAddress;

    // implementAddress
    address public implementationAddress;

    constructor(address _dappCreatorAddress) {
        dappCreatorAddress = _dappCreatorAddress;
        implementationAddress = address(new CharacterToken());

        _setupRole(IMPLEMENTATION_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /*
    *   Create instance of NftCollection
    *   @param {uint8} _maxRarityValue - the maximum of the rarity's indexs
    */
    function createNftCollection(
        string memory _name,
        string memory _symbol,
        uint8 _maxRarityValue,
        string[] memory _cids,
        uint256[] memory _prices
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        require(uint8(_cids.length) == _maxRarityValue, "Invalid cids legnth");
        require(uint8(_prices.length) == _maxRarityValue, "Invalid prices legnth");

        address collection = Clones.clone(implementationAddress);

        // Initialize
        CharacterToken(collection).initialize(
            _name,
            _symbol,
            _maxRarityValue,
            _cids,
            dappCreatorAddress
        );
        
        // Add new collection to DappCreator
        DaapNFTCreator(dappCreatorAddress).addNewCollection(
            collection,
            _prices
        );

        // set Minter Role for Daap Creator
        CharacterToken(collection).setMinterRole(dappCreatorAddress);

        nftCollectionsAddress.push(collection);
        isInListCollections[collection] = true;
        
        emit CreateNftCollection(
            address(collection),
            _maxRarityValue,
            dappCreatorAddress
        );
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Getters
    function getAllCollections() external view onlyRole(IMPLEMENTATION_ROLE) returns(address[] memory) {
        return nftCollectionsAddress;
    }

    function getCurrentDappCreatorAddress() external view onlyRole(IMPLEMENTATION_ROLE) returns(address) {
        return dappCreatorAddress;
    }

    function isValidNftCollection(address _nftCollection) external view returns(bool) {
        return isInListCollections[_nftCollection];
    }

    // Setters
    function setDappCreatorAddress(address _dappCreatorAddress) external onlyRole(IMPLEMENTATION_ROLE) {
        dappCreatorAddress = _dappCreatorAddress;
        emit SetDappCreator(_dappCreatorAddress);
    }

    /**
     *  function Set new minter Role for a collection
     */
    function setNewMinter(
        address _characterToken,
        address _newMinter
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        CharacterToken(_characterToken).setMinterRole(_newMinter);
        emit SetNewMinterRole(_characterToken, _newMinter);
    }

    /**
     *  Function allows Factory as ADMIN of all NFT collection to upgrade new rarity for existing nft collection
     */
    function AddNewNftRarities(
        ICharacterToken _nftCollection,
        uint256[] memory _prices,
        string[] memory _cids
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        uint8 _currMaxRarity = _nftCollection.getMaxRarityValue();
        
        // Add prices for new rarities 
        DaapNFTCreator(dappCreatorAddress).upgradeNewNftRarity(
            _nftCollection,
            _prices
        );

        // Add new cids for new rarities
        _nftCollection.addCidsForNewRarities(_cids);

        // Set new max of rarities
        _nftCollection.setNewMaxOfRarity(_currMaxRarity + uint8(_prices.length));
        emit AddNewNftRariies(address(_nftCollection), _prices, _currMaxRarity, _currMaxRarity + uint8(_prices.length));
    }

    /**
     *  Function allow Factory to change price of one existing NFT rarity
     */
    function updatePrice(
        ICharacterToken _nftCollection,
        uint8 _rarity,
        uint256 _newPrice
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        require(isInListCollections[address(_nftCollection)], "Invalid NFT collection");
        require(_nftCollection.getMaxRarityValue() >= _rarity, "Invalid rarity value");
        DaapNFTCreator(dappCreatorAddress).updatePrice(_nftCollection, _rarity, _newPrice);
        emit UpdateNewPrice(address(_nftCollection), _rarity, _newPrice);
    }
    
    /**
     *  Function allow Factory to change cid of one existing NFT rarity
     */
    function updateCidOfRarity(
        ICharacterToken _nftCollection,
        uint8 _rarity,
        string memory _newCid
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        require(isInListCollections[address(_nftCollection)], "Invalid NFT collection");
        require(_nftCollection.getMaxRarityValue() >= _rarity, "Invalid rarity value");
        _nftCollection.updateCidOfExistingRarity(_rarity, _newCid);
        emit UpdateCidOfExistingRarity(address(_nftCollection), _rarity, _newCid);
    }
}