// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./CharacterDetails.sol";
import "./interfaces/ICharacterDesign.sol";
import "./Utils.sol";
import "./interfaces/ICharacterStats.sol";

contract CharacterDesign is AccessControlUpgradeable, UUPSUpgradeable, ICharacterDesign {
    using CharacterDetails for CharacterDetails.Details;
    using Counters for Counters.Counter;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");

    event CreateRandomToken(uint256 id, uint256 details);
    event OnChain(uint256 id, uint256 details);
    event OffChain(uint256 id, uint256 details);
    event OwnerOnChain(uint256 id, uint256 details);

    struct CharacterDesignDetail {
        string name;
        uint32[] properties;
    }

    IERC721 public characterToken;

    // Mapping from token ID to token details.
    mapping(uint256 => CharacterDesignDetail) public characterDetails;

    // Counter for rarity list
    Counters.Counter public rarityId;

    // Rarity Type
    mapping(uint8 => RarityDetail) public rarityList;

    // Total supply of NFT
    uint256 public totalSupply;

    uint public constant KTN_DECIMALS = 10 ** 18;

    constructor () public {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);

        totalSupply = 100000000;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** Sets the token of Design. */
    function setCharacterToken(address _characterToken)
        external
        onlyRole(DESIGNER_ROLE)
    {
        characterToken = IERC721(_characterToken);
    }

    /** Sets the total Supply. */
    function setTotalSupply(uint256 value) external onlyRole(DESIGNER_ROLE) {
        totalSupply = value;
    }

    /** Gets totalSupply */
    function getTotalSupply() external view override returns (uint256) {
        return totalSupply;
    }

    /** Gets details of each token with tokenId */
    function getTokenDetail(uint256 tokenId) external view returns (CharacterDesignDetail memory) {
        return characterDetails[tokenId];
    }

    /** Get list token details by list tokenIds */
    function getTokenDetails(uint256[] memory tokenIds)
        external
        view
        returns (CharacterDesignDetail[] memory)
    {
        CharacterDesignDetail[] memory result = new CharacterDesignDetail[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            result[i] = characterDetails[tokenIds[i]];
        }
        return result;
    }

    /** Add new Rarity type */
    function addNewRarity(string calldata _rarityName, uint256 _totalSupply) external onlyRole(DESIGNER_ROLE) {
        uint8 _newRarityId = uint8(rarityId.current());
        rarityList[_newRarityId] = RarityDetail(
            _rarityName,
            _totalSupply
        );
        totalSupply += _totalSupply;
        rarityId.increment();
    }

    /** Get details of each rarity */
    function getRarityDetails(uint8 _rarityId) external returns (RarityDetail memory){
        return rarityList[_rarityId];
    }

    /**
     *      Get latest rarityId
     */
    function lastRarityId() external returns (uint8) {
        return uint8(rarityId.current());
    }

    /**
     *      Create new Design for NFT with specific tokenId
     */
    function createNewDesign(uint256 _tokenId) external onlyRole(DESIGNER_ROLE) {
        CharacterDesignDetail memory _designDetail;
        _designDetail.name = string(abi.encodePacked("NFT", _tokenId));
        characterDetails[_tokenId] = _designDetail;
    }
}
