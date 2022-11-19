// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../MysteryBoxNFT.sol";
import "../BoxNFTCreator.sol";
import "../interfaces/IBoxesConfigurations.sol";

contract KatanaBoxFactory is AccessControl {

    using EnumerableSet for EnumerableSet.AddressSet;
    
    event CreateNftCollection(
        address nftAddress,
        address dappCreatorAddress
    );
    event SetDappCreator(address newDappCreator);
    event SetNewMinterRole(address boxCollection, address newMinter);
    event UpdateNewPrice(address boxCollection, uint256 newPrice);
    event UpdateBuyableMint(address boxCollection, bool buyable);
    event SetConfiguration(address newConfiguration);

    bytes32 public constant IMPLEMENTATION_ROLE = keccak256("IMPLEMENTATION_ROLE");
    
    
    // List of NFT collections
    EnumerableSet.AddressSet private nftCollectionsList;

    // Wrapper Creator address: using for calling from dapp
    address public dappCreatorAddress;

    // implementAddress
    address public implementationAddress;

    // This contract config metadata for all collections
    IBoxesConfigurations public boxConfigurations;


    constructor(
        address _dappCreatorAddress, 
        IBoxesConfigurations _boxConfig
    ) {
        dappCreatorAddress = _dappCreatorAddress;
        boxConfigurations = _boxConfig;
        implementationAddress = address(new MysteryBoxNFT(_dappCreatorAddress, address(_boxConfig)));

        _setupRole(IMPLEMENTATION_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*
       @dev: Set new configuration
       @param {address} _address - This is address of new configuration
    */
    function setConfiguration(IBoxesConfigurations _boxConfig) external onlyRole(IMPLEMENTATION_ROLE) {
        require(address(_boxConfig) != address(0x0), "Address of configuration must be required.");
        boxConfigurations = _boxConfig;
        emit SetConfiguration(address(_boxConfig));
    }

    /*
    *   Create instance of BoxMystery
    */
    function createBoxMystery(
        string memory _name,
        string memory _symbol,
        IERC20 _payToken
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        address collection = Clones.clone(implementationAddress);
        // Initialize
        MysteryBoxNFT(collection).initialize(
            _name,
            _symbol,
            _payToken
        );
        nftCollectionsList.add(collection);
         // Add new collection to configuration
        boxConfigurations.InsertNewCollectionAddress(collection);

        emit CreateNftCollection(
            address(collection),
            dappCreatorAddress
        );
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getCurrentDappCreatorAddress() external view onlyRole(IMPLEMENTATION_ROLE) returns(address) {
        return dappCreatorAddress;
    }

    function isValidNftCollection(address _nftCollection) external view returns(bool) {
        return nftCollectionsList.contains(_nftCollection);
    }

    // Setters
    function setDappCreatorAddress(address _dappCreatorAddress) external onlyRole(IMPLEMENTATION_ROLE) {
        dappCreatorAddress = _dappCreatorAddress;
        emit SetDappCreator(_dappCreatorAddress);
    }

    /**
     *  @notice Function Set new minter Role for a collection
     *  @dev Call to MysteryBoxNFT to set MINTER_ROLE
     */
    function setNewMinter(
        address _boxNFT,
        address _newMinter
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        MysteryBoxNFT(_boxNFT).grantRole(MysteryBoxNFT(_boxNFT).MINTER_ROLE(), _newMinter);
        emit SetNewMinterRole(_boxNFT, _newMinter);
    }

    /**
     *  Function allow Factory to change price of one existing NFT.
     */
    function updatePrice(
        IMysteryBoxNFT _nftCollection,
        uint256 _newPrice
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        // require(isInListCollections[address(_nftCollection)], "Invalid NFT collection");
        BoxNFTCreator(dappCreatorAddress).updatePrice(_newPrice);
        emit UpdateNewPrice(address(_nftCollection), _newPrice);
    }
    
    /**
     *  Function allow Factory to change flag buyable of one contract BoxMystery.
     */
    function updateBuyable(
        IMysteryBoxNFT _nftCollection,
        bool _isBuyable
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        // require(isInListCollections[address(_nftCollection)], "Invalid NFT collection");
        MysteryBoxNFT(address(_nftCollection)).setBuyable(_isBuyable);
        // emit UpdateNewPrice(address(_nftCollection), _newPrice);
    }

    function updateRoleBox(
        bytes32 _role, 
        address _account,
        address  _boxAddress
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        MysteryBoxNFT(_boxAddress).grantRole(_role, _account);
    }
}
