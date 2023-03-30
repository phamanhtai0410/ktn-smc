// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Collection.sol";
import "./interfaces/IConfiguration.sol";
import "./interfaces/ICollection.sol";

contract KatanaNftFactory is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Interface Execution Function's enum and event
    enum Operation {
        Call,
        DelegateCall
    }
    event Execution(
        address to,
        uint256 value,
        bytes data,
        Operation operation,
        bool status
    );

    // Factory's events
    event CreateNftCollection(address nftAddress);
    event SetConfiguration(address newConfiguration);
    event SetNewMinterRole(address nftCollection, address newMinter);
    event ConfigNewTotalSupply(address _collection, uint256 _newTotal);

    bytes32 public constant IMPLEMENTATION_ROLE =
        keccak256("IMPLEMENTATION_ROLE");

    // List of NFT collections
    EnumerableSet.AddressSet private nftCollectionsList;

    // Wrapper Creator address: using for calling from dapp
    address public dappCreatorAddress;

    // This contract config metadata for all collections
    IConfiguration public nftConfiguration;

    // implementAddress of NFT collection
    address public implementationAddress;

    constructor(IConfiguration _nftConfiguration) {
        nftConfiguration = _nftConfiguration;
        implementationAddress = address(new KatanaInuCollection());

        _setupRole(IMPLEMENTATION_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*
       @dev: Set new configuration
       @param {address} _address - This is address of new configuration
    */
    function setConfiguration(
        IConfiguration _nftConfiguration
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        require(
            address(_nftConfiguration) != address(0x0),
            "Address of configuration must be required."
        );
        nftConfiguration = _nftConfiguration;
        emit SetConfiguration(address(_nftConfiguration));
    }

    /**
     *      Config collection
     */
    function configCollection(
        address _collectionAddress,
        uint256 _nftIndex,
        uint256 _price,
        string memory _baseMetadataUri
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        _configOneCollection(
            _collectionAddress,
            _nftIndex,
            _price,
            _baseMetadataUri
        );
        // TODO: emit event when config
    }

    function _configOneCollection(
        address _collectionAddress,
        uint256 _nftIndex,
        uint256 _price,
        string memory _baseMetadataUri
    ) internal {
        nftConfiguration.configCollection(
            _collectionAddress,
            _nftIndex,
            _price,
            _baseMetadataUri
        );
    }

    /**
     *      Config collection
     */
    function configNftCollectionURI(
        address _collectionAddress,
        string memory _baseMetadataUri
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        nftConfiguration.configCollectionURI(
            _collectionAddress,
            _baseMetadataUri
        );
    }

    /*
     *   Create instance of COLLECTION
     */
    function createNftCollection(
        string memory _name,
        string memory _symbol,
        string memory _baseMetadataUri,
        uint256 _totalSupply,
        address _treasuryAddress,
        uint96 _royaltyRate,
        uint256[] memory _prices
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        address collection = Clones.clone(implementationAddress);

        // Initialize
        KatanaInuCollection(collection).initialize(
            _name,
            _symbol,
            _totalSupply
        );

        // Call to config the default royalty fee rate
        KatanaInuCollection(collection).configRoyalty(
            _treasuryAddress,
            _royaltyRate
        );

        // Add new collection to configuration
        nftConfiguration.InsertNewCollectionAddress(collection);
        nftCollectionsList.add(collection);

        // Config prices
        for (uint i = 0; i < _prices.length; i++) {
            _configOneCollection(collection, i, _prices[i], _baseMetadataUri);
        }

        emit CreateNftCollection(collection);
    }

    /**
     * Function alows IMPLEMENTATION to config new totalSupply
     * @param _collection The address of the NFT collection that wants to config
     * @param _newTotal The new total value
     */
    function configNewTotalSupply(
        address _collection,
        uint256 _newTotal
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        KatanaInuCollection(_collection).setTotalSupply(_newTotal);
        emit ConfigNewTotalSupply(_collection, _newTotal);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// Getters
    function getCurrentDappCreatorAddress() external view returns (address) {
        return nftConfiguration.getNftCreator();
    }

    /**
     *  @notice Function allows to get the current Nft Configurations
     */
    function getCurrentConfiguration() external view returns (address) {
        return address(nftConfiguration);
    }

    function getCollectionAddress(
        uint256 index
    ) external view returns (address) {
        return nftCollectionsList.at(index);
    }

    function isValidNftCollection(
        address _nftCollection
    ) external view returns (bool) {
        return nftCollectionsList.contains(_nftCollection);
    }

    // Setters
    /**
     *  @notice Function Set new minter Role for a collection
     *  @dev Call to NFT collection to set MINTER_ROLE
     */
    function setNewMinter(
        address _characterToken,
        address _newMinter
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        KatanaInuCollection(_characterToken).setMinterRole(_newMinter);
        emit SetNewMinterRole(_characterToken, _newMinter);
    }

    /**
     *  @notice Functions allows IMPLEMENTATION_ROLE to update state of disable minting
     */
    function updateStateDisableMinting(
        address _nftCollection,
        bool _newState
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        ICollection(_nftCollection).updateDisableMinting(_newState);
    }

    /**
     *  @notice Function allows IMPLEMENTATION_ROLE to switch mode of free transfering NFT
     */
    function switchFreeTransferMode(
        address _nftColleciton
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        ICollection(_nftColleciton).switchFreeTransferMode();
    }

    /**
     *  @notice Function execute flex by abi decoded and params
     */
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
                success := delegatecall(
                    txGas,
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(
                    txGas,
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
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
        Operation operation
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        bool success = execute(to, value, data, operation, txGas);
        emit Execution(to, value, data, operation, success);
    }
}
