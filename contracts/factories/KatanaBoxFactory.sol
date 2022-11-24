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
import "../interfaces/INftFactory.sol";


contract KatanaBoxFactory is AccessControl {

    using EnumerableSet for EnumerableSet.AddressSet;
    
    event CreateBoxCollection(
        address boxAddress,
        address boxCreatorAddress
    );
    event SetDappCreator(address newDappCreator);
    event SetNewMinterRole(address boxCollection, address newMinter);
    event UpdateNewBoxConfig(address boxCollection, string cid, uint256 price, uint256 defaultIndex);
    event UpdateNewDropRate(address boxAddress, uint256 rarity, uint256 meshIndex, uint256 meshMaterial, uint256 proportion);
    event UpdateBuyableMint(address boxCollection, bool buyable);
    event SetConfiguration(address newConfiguration);
    event SetNftFactory(address newNftFactory);

    bytes32 public constant IMPLEMENTATION_ROLE = keccak256("IMPLEMENTATION_ROLE");
    
    
    // List of BOX collections
    EnumerableSet.AddressSet private boxList;

    // Wrapper Creator address: using for calling from dapp
    address public boxCreatorAddress;

    // implementAddress
    address public implementationAddress;

    // This contract config metadata for all collections
    IBoxesConfigurations public boxConfigurations;

    // This contract stores NFT Factory
    INftFactory public nftFactory;

    constructor(
        address _boxCreatorAddress, 
        IBoxesConfigurations _boxConfig,
        INftFactory _nftFactory
    ) {
        boxCreatorAddress = _boxCreatorAddress;
        boxConfigurations = _boxConfig;
        nftFactory = _nftFactory;

        implementationAddress = address(new MysteryBoxNFT());

        _setupRole(IMPLEMENTATION_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*
    *   Create instance of BoxMystery
    */
    function createBoxMystery(
        string memory _name,
        string memory _symbol,
        IERC20 _payToken,
        ICharacterToken _characterToken
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        address collection = Clones.clone(implementationAddress);

        // Initialize
        MysteryBoxNFT(collection).initialize(
            _name,
            _symbol,
            _payToken
        );

        boxList.add(collection);

        // grant role MINTER for new box
        nftFactory.setNewMinter(
            address(_characterToken),
            collection
        );

         // Add new collection to configuration
        boxConfigurations.InsertNewCollectionAddress(
            address(_characterToken),
            collection
        );

        emit CreateBoxCollection(
            address(collection),
            boxCreatorAddress
        );
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getCurrentDappCreatorAddress() external view onlyRole(IMPLEMENTATION_ROLE) returns(address) {
        return boxCreatorAddress;
    }

    function isValidBoxAddress(address _boxAddress) external view returns(bool) {
        return boxList.contains(_boxAddress);
    }

    /// @notice Function allows to get Informations of one box
    /// @dev Call to Box Configurations to get infos
    /// @param _boxAddress a parameter just show which contract need to get infos about
    /// @return Documents the return variables of the informations of one box instant
    function getBoxInfos(address _boxAddress) external view returns(string memory, uint256 , uint256) {
        return boxConfigurations.getBoxInfos(_boxAddress);
    }

    /**
     *  @notice Function allows to get box address in Box Address List
     */
    function getBoxAddresAt(uint256 _index) external view returns(address) {
        return boxList.at(_index);
    }

    /**
     *  @notice Function that returns the address of the box configurations contract
     */
    function getBoxesConfigurations() external view returns(address) {
        return address(boxConfigurations);
    }

    /**
     *  @notice Function that returns the address of the Box Creator
     */
    function getBoxCreator() external view returns(address) {
        return boxCreatorAddress; 
    }

    /**
     *  @notice Funtion get nftCollection from BoxesCOnfigurations
     */
    function NftCollection(address _boxAddress) external view returns(address) {
        return boxConfigurations.getNftCollection(_boxAddress);
    }

    // Setters
    function setDappCreatorAddress(address _boxCreatorAddress) external onlyRole(IMPLEMENTATION_ROLE) {
        boxCreatorAddress = _boxCreatorAddress;
        emit SetDappCreator(_boxCreatorAddress);
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

    function setNftFactory(INftFactory _nftFactory) external onlyRole(IMPLEMENTATION_ROLE) {
        nftFactory = _nftFactory;
        emit SetNftFactory(address(_nftFactory));
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
     *  Function allow Factory to change config of one existing Box.
     */
    function configOne(
        IMysteryBoxNFT _boxAddress,
        string memory _cid,
        uint256 _price,
        uint256 _defaultIndex
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        require(boxList.contains(address(_boxAddress)), "Invalid Box Contract");
        boxConfigurations.configOne(
            address(_boxAddress),
            _cid,
            _price,
            _defaultIndex
        );
        emit UpdateNewBoxConfig(address(
            _boxAddress),
            _cid,
            _price,
            _defaultIndex
        );
    }
    
    /**
     *  @notice Function allows Factory to config one dropRate of a box
     */
    function configDropRate(
        address _boxAddress,
        uint256 _rarity,
        uint256 _meshIndex,
        uint256 _meshMaterial,
        uint256 _proportion 
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        require(boxList.contains(_boxAddress), "Invalid Box Contract");
        boxConfigurations.configDroppedRate(
            _boxAddress,
            _rarity,
            _meshIndex,
            _meshMaterial,
            _proportion
        );
        emit UpdateNewDropRate(
            _boxAddress,
            _rarity,
            _meshIndex,
            _meshMaterial,
            _proportion
        );
    }

    /**
     *  Function allow Factory to change flag buyable of one contract BoxMystery.
     */
    function updateBuyable(
        IMysteryBoxNFT _boxCollection,
        bool _isBuyable
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        MysteryBoxNFT(address(_boxCollection)).setBuyable(_isBuyable);
    }

    function updateRoleBox(
        bytes32 _role, 
        address _account,
        address  _boxAddress
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        MysteryBoxNFT(_boxAddress).grantRole(_role, _account);
    }

    /// Internals
}
