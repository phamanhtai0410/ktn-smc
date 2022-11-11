// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import "./CharacterToken.sol";

contract KatanaNftFactory is AccessControl {

    event CreateNftCollection(
        address nftAddress,
        uint8 maxRarityValue,
        address dappCreatorAddress
    );
    event RemoveCampaign(address campaignAddress);

    bytes32 public constant IMPLEMENTATION_ROLE = keccak256("IMPLEMENTATION_ROLE");

    // RinZCampaigns Address list
    address[] public nftCollectionsAddress;

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
    *   Create instance of RinZCampaign
    *   @param {uint8} _maxRarityValue - the maximum of the rarity's indexs
    */
    function createCampaign(
        uint8 _maxRarityValue
    ) external onlyRole(IMPLEMENTATION_ROLE) {
        address collection = Clones.clone(implementationAddress);

        // Initialize
        CharacterToken(collection).initialize(
            _maxRarityValue
        );

        // TODO: grant role DESIGNER_ROLE for new collection in DappCreator
        // Note: Factory need role UPGRADER to grant 
        
        // TODO: set MINTER_ROLE for [dappCreator, Dev_wallet] in new collection contract
        // TODO: call to dappCreator to submit new collection

        nftCollectionsAddress.push(address(collection));
        
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
    }
}