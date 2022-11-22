// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../CharacterToken.sol";
import '../interfaces/INftConfigurations.sol';


contract KatanaNftFactory is AccessControl {

    using EnumerableSet for EnumerableSet.AddressSet;

    event CreateNftCollection(
        address nftAddress,
        address dappCreatorAddress
    );

    enum Operation {Call, DelegateCall}
    event Execution(address to, uint256 value, bytes data, Operation operation, bool status);

    event SetDappCreator(address newDappCreator);
    event SetConfiguration(address newConfiguration);
    event ConfigOne(address _nftCollection, uint256 _rarity, uint256 _meshIndex, uint256 _price, uint256 _meshMaterial, string _cid);
    event ConfigMesh(address _nftCollection, uint256 _rarity, uint256 _meshIndex, uint256 _price);

    event SetNewMinterRole(address nftCollection, address newMinter);

    bytes32 public constant IMPLEMENTATION_ROLE = keccak256("IMPLEMENTATION_ROLE");

    // List of NFT collections
    EnumerableSet.AddressSet private nftCollectionsList;

    // Wrapper Creator address: using for calling from dapp
    address public dappCreatorAddress;

    // This contract config metadata for all collections
    INftConfigurations public nftConfigurations;

    // implementAddress
    address public implementationAddress;

    constructor(address _dappCreatorAddress, INftConfigurations _nftConfigurations) {

        dappCreatorAddress = _dappCreatorAddress;

        nftConfigurations = _nftConfigurations;

        implementationAddress = address(new CharacterToken());

        _setupRole(IMPLEMENTATION_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*
       @dev: Set new configuration
       @param {address} _address - This is address of new configuration
    */
    function setConfiguration(INftConfigurations _nftConfigurations) external onlyRole(IMPLEMENTATION_ROLE) {
        require(address(_nftConfigurations) != address(0x0), "Address of configuration must be required.");
        nftConfigurations = _nftConfigurations;
        emit SetConfiguration(address(_nftConfigurations));
    }

    /*
    *   Create instance of NftCollection
    *   @param {uint8} _maxRarityValue - the maximum of the rarity's indexs
    */
    function createNftCollection(
        string memory _name,
        string memory _symbol
    ) external onlyRole(IMPLEMENTATION_ROLE) {

        address collection = Clones.clone(implementationAddress);

        // Initialize
        CharacterToken(collection).initialize(
            _name,
            _symbol,
            dappCreatorAddress,
            address(nftConfigurations)
        );

        // Add new collection to configuration
        nftConfigurations.InsertNewCollectionAddress(collection);


        nftCollectionsList.add(collection);

        emit CreateNftCollection(
            collection,
            dappCreatorAddress
        );
    }

    /*
        @dev
        @param {address} _nftCollection
        @param {uint256} _rarity
        @param {uint256} _meshIndex
        @param {uint256} _price
        @param {uint256} _meshMaterial
        @param {string} _cid

    */
    function configOne(
        address _nftCollection,
        uint256 _rarity,
        uint256 _meshIndex,
        uint256 _price,
        uint256 _meshMaterial,
        string memory _cid
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        require(nftCollectionsList.contains(_nftCollection), "Collection: The collection doesn't exist");
        nftConfigurations.configOne(
            _nftCollection,
            _rarity,
            _meshIndex,
            _price,
            _meshMaterial,
            _cid
        );
        emit ConfigOne(
            _nftCollection,
            _rarity,
            _meshIndex,
            _price,
            _meshMaterial,
            _cid
        );
    }

    /*
        @dev
        @param {address} _nftCollection
        @param {uint256} _rarity
        @param {uint256} _meshIndex
        @param {uint256} _price
        @param {uint256} _meshMaterial
        @param {string} _cid

    */
    function configMesh(
        address _nftCollection,
        uint256 _rarity,
        uint256 _meshIndex,
        uint256 _price
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        require(nftCollectionsList.contains(_nftCollection), "Collection: The collection doesn't exist");
        nftConfigurations.configMesh(
            _nftCollection,
            _rarity,
            _meshIndex,
            _price
        );
        emit ConfigMesh(
            _nftCollection,
            _rarity,
            _meshIndex,
            _price
        );
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getCurrentDappCreatorAddress() external view onlyRole(IMPLEMENTATION_ROLE) returns (address) {
        return dappCreatorAddress;
    }

    function getCollectionAddress(uint256 index) external view returns (address) {
        return nftCollectionsList.at(index);
    }

    function isValidNftCollection(address _nftCollection) external view returns (bool) {
        return nftCollectionsList.contains(_nftCollection);
    }

    // Setters
    function setDappCreatorAddress(address _dappCreatorAddress) external onlyRole(IMPLEMENTATION_ROLE) {
        dappCreatorAddress = _dappCreatorAddress;
        emit SetDappCreator(_dappCreatorAddress);
    }

    /**
     *  @notice Function Set new minter Role for a collection
     *  @dev Call to NFT collection to set MINTER_ROLE
     */
    function setNewMinter(
        address _characterToken,
        address _newMinter
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        CharacterToken(_characterToken).setMinterRole(_newMinter);
        emit SetNewMinterRole(_characterToken, _newMinter);
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
    /*
        @dev This method is only meant for estimation purpose, therefore the call will always revert and encode the result in the revert data.
    */
    function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // Convert response to string and return via error message
        revert(string(abi.encodePacked(requiredGas)));
    }
    // Execute tx
    function execTx(
        address to,
        uint256 value,
        uint256 txGas,
        bytes calldata data,
        Operation operation) external onlyRole(IMPLEMENTATION_ROLE) {
        bool success = execute(to, value, data, operation, txGas);
        emit Execution(to, value, data, operation, success);
    }
}
