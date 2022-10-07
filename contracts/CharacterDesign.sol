// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./CharacterDetails.sol";
import "./interfaces/ICharacterDesign.sol";
import "./Utils.sol";
import "./interfaces/ICharacterStats.sol";

contract CharacterDesign is AccessControlUpgradeable, UUPSUpgradeable, ICharacterDesign {
    using CharacterDetails for CharacterDetails.Details;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");

    event CreateRandomToken(uint256 id, uint256 details);
    event OnChain(uint256 id, uint256 details);
    event OffChain(uint256 id, uint256 details);
    event OwnerOnChain(uint256 id, uint256 details);

    IERC721 public characterToken;

    ICharacterStats[] public characterStats;

    // Mapping from token ID to token details.
    mapping(uint256 => uint256) public characterDetails;


    // Mapping from rate to rarity to character ids.
    mapping(uint256 => uint256[]) public rarityCharacter;

    // Number of token per user
    uint256 public tokenLimit;
    // Character: 0, 1, 2...
    uint256 private characterType;

    uint256[] private dropRateNormal;
    uint256[] private dropRateGolden;
    uint256[] private dropRateBasket;
    uint256[] private factionRate;

    // Mint cost base boxType index: 1 -> BOX_TYPE_NORMAL; 2 -> BOX_TYPE_GOLDEN; 3 -> BOX_TYPE_BASKET
    uint256[] private mintCost;
    uint public constant KTN_DECIMALS = 10 ** 18;

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);

        tokenLimit = 100;
        characterType = 15;

        // Box random rarity
        dropRateNormal = [7058, 2705, 214, 20, 3, 0];
        dropRateGolden = [4842, 4467, 622, 60, 7, 2];
        dropRateBasket = [0, 8541, 1159, 250, 30, 20];

        // Mint cost
        mintCost.push(1000 ether); // For skip
        mintCost.push(40 ether); // Normal
        mintCost.push(55 ether); // Golden


        // Character stats, start from Character index 0
        characterStats.push(ICharacterStats(0x987453cD03B205F1a41337f6FE8D701122Cb0824)); // address StatsTop10
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

    /** Sets the design. */
    function setCharacterToken(address contractAddress)
        external
        onlyRole(DESIGNER_ROLE)
    {
        characterToken = IERC721(contractAddress);
    }

    /** Set character stats */
    function setCharacterStats(address addressTop20, address addressTop40, address addressTop60, address addressTop80)
        external
        onlyRole(DESIGNER_ROLE)
    {

        // Clear hero Stats
        delete characterStats;
        characterStats.push(ICharacterStats(addressTop20));
        characterStats.push(ICharacterStats(addressTop40));
        characterStats.push(ICharacterStats(addressTop60));
        characterStats.push(ICharacterStats(addressTop80));
    }

    function getCharacterStats(uint256 characterId) external view returns (ICharacterStats.Stats memory stats) {
        stats = characterStats[characterId/20].getStats(characterId);
        return stats;
    }

    /** Update mapping rarity-characters */
    function setrarityCharacter(uint256 rarity, uint256[] calldata characterIds) external onlyRole(DESIGNER_ROLE) {
        rarityCharacter[rarity] = characterIds;
    }

    /** Get list characters by rarity  */
    function getrarityCharacters(uint256 rarity) external view returns( uint256[] memory)
    {
        return rarityCharacter[rarity];
    }

    /** Sets the token limit. */
    function setTokenLimit(uint256 value) external onlyRole(DESIGNER_ROLE) {
        tokenLimit = value;
    }

    /** Sets number of characters */
    function setCharacterType(uint256 value) external onlyRole(DESIGNER_ROLE) {
        characterType = value;
    }

    // /** Sets the drop rate. */
    function setDropRateNormal(uint256[] memory value)
        external
        onlyRole(DESIGNER_ROLE)
    {
        dropRateNormal = value;
    }

    function setDropRateGolden(uint256[] memory value)
        external
        onlyRole(DESIGNER_ROLE)
    {
        dropRateGolden = value;
    }

    function setDropRateBasket(uint256[] memory value)
        external
        onlyRole(DESIGNER_ROLE)
    {
        dropRateBasket = value;
    }

    /** Sets the minting fee. */
    function setMintCost(uint256 rarity, uint256 value) external onlyRole(DESIGNER_ROLE) {
        mintCost[rarity] = value * KTN_DECIMALS;
    }

    function getTokenLimit() external view override returns (uint256) {
        return tokenLimit;
    }

    function getCharacterType() external view returns (uint256) {
        return characterType;
    }

    function getDropRateNormal() external view returns (uint256[] memory) {
        return dropRateNormal;
    }

    function getDropRateGolden() external view returns (uint256[] memory) {
        return dropRateGolden;
    }

    function getDropRateBasket() external view returns (uint256[] memory) {
        return dropRateBasket;
    }

    function getMintCost(uint256 boxType) external view override returns (uint256) {
        return mintCost[boxType];
    }

    function getTokenDetail(uint256 tokenId) external view returns (uint256) {
        return characterDetails[tokenId];
    }

    /** Get list token details by list tokenIds */
    function getTokenDetails(uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            result[i] = characterDetails[tokenIds[i]];
        }
        return result;
    }

    function createRandomToken(
        uint256 id,
        uint256 rarity
    ) external override returns (uint256 nextSeed) {
        address nftRequester = msg.sender;
        require(
            nftRequester == address(characterToken),
            "Only CharacterToken (NFT) allowed"
        );

        CharacterDetails.Details memory details;
        uint256 seed = 1;
        // For random rarity
        uint256[] memory dropRate = dropRateNormal;
        if (rarity == CharacterDetails.BOX_TYPE_GOLDEN) {
            dropRate = dropRateGolden;
        } else if (rarity == CharacterDetails.BOX_TYPE_BASKET) {
            dropRate = dropRateBasket;
        }

        if (rarity == CharacterDetails.ALL_RARITY) {
            // Random rarity.
            (seed, details.rarity) = Utils.randomByWeights(seed, dropRate);
        } else {
            // Specified rarity.
            details.rarity = rarity - 1;
        }

        // Random character in rarity and faction
        uint256[] memory listCharacterIds = rarityCharacter[details.rarity];
        uint256 characterIndex;
        (seed, characterIndex) = Utils.randomRangeInclusive(seed, 0, listCharacterIds.length-1);
        uint256 characterId = listCharacterIds[characterIndex];

        details.id = id;
        details.is_onchain = CharacterDetails.OFF_CHAIN;
        details.character_id = characterId;
        details.rarity = rarity;
        details.level = 1;
        // Get stats base. characterId 0->19 = characterStats[0], characterId 20->39 = characterStats[1], characterId 40->59 = characterStats[2], characterId 60->79 = characterStats[3]
        ICharacterStats.Stats memory stats = characterStats[characterId/20].getStats(characterId);
        details.rarity = stats.rarity;
        details.health = stats.health;
        details.speed = stats.speed;
        details.armor = stats.armor;
        details.crit_chance = stats.crit_chance;
        details.crit_damage = stats.crit_damage;
        details.dodge = stats.dodge;
        details.type_attack = stats.type_attack;
        details.damage = stats.damage;
        characterDetails[id] = details.encode();
        emit CreateRandomToken(id, characterDetails[id]);
    }

    function _transferable(
        address from,
        address to,
        uint256 id
    ) external view override returns (bool) {
        CharacterDetails.Details memory details = CharacterDetails.decode(characterDetails[id]);
        // Can not tranfer if off chain
        if (details.is_onchain != CharacterDetails.ON_CHAIN) {
            return false;
        }
        return true;
    }

    /** Set character stats and update warrior on chain. */
    function onChain(uint256 tokenId, uint256 characterEncoded) external onlyRole(DESIGNER_ROLE) {
        // TODO verify characterEncoded if external for all user
        CharacterDetails.Details memory details = CharacterDetails.decode(characterEncoded);
        details.is_onchain = CharacterDetails.ON_CHAIN;
        characterDetails[tokenId] = details.encode();
        emit OnChain(tokenId, characterDetails[tokenId]);
    }

    /** Update warrior off chain for the owner. */
    function offChain(uint256 tokenId) external {
        address owner = msg.sender;
        require(characterToken.ownerOf(tokenId) == owner, "Token not owned");

        CharacterDetails.Details memory details = CharacterDetails.decode(characterDetails[tokenId]);
        details.is_onchain = CharacterDetails.OFF_CHAIN;
        characterDetails[tokenId] = details.encode();
        emit OffChain(tokenId, characterDetails[tokenId]);
    }

}
