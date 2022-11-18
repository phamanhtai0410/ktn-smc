// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ICharacterToken.sol";
import "./libraries/BoxNFTDetails.sol";

contract BoxesConfigurations is
    AccessControlUpgradeable
{
    // Event
    event AddNewBoxInstant(address boxContract, uint256[] rarityProportions, uint8 defaultRarity);


    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Address of NFT collection
    ICharacterToken public NFT_COLLECTION;

    // Store boxInstant's Instant
    mapping(address => BoxNFTDetails.BoxConfigurations) public boxInfos;

    constructor (address _nftColelction) {
        NFT_COLLECTION = ICharacterToken(_nftColelction);
    }

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
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

    /**
     *  @notice Function returns the proportions of each rarity of the specificed box Instant and boxType- index of box
     * @param _boxAddress The address of box Instant that wants to check
     */
    function getBoxInfos(
        address _boxAddress
    ) public view returns(BoxNFTDetails.BoxConfigurations memory){
        return boxInfos[_boxAddress];
    }
}