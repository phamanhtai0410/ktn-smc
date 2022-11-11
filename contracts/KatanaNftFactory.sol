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
        implementationAddress = address(new CharacterToken(_dappCreatorAddress));

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
        uint256[] memory _prices
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        address collection = Clones.clone(implementationAddress);

        // Initialize
        CharacterToken(collection).initialize(
            _name,
            _symbol,
            _maxRarityValue
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

    // Setters
    function setDappCreatorAddress(address _dappCreatorAddress) external onlyRole(IMPLEMENTATION_ROLE) {
        dappCreatorAddress = _dappCreatorAddress;
        implementationAddress = address(new CharacterToken(_dappCreatorAddress));
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
}