// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./CharacterDetails.sol";
import "./interfaces/INFTToken.sol";
import "./interfaces/ICharacterItem.sol";


contract CharacterToken is
    ERC721Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    INFTToken
{
    struct MintingOrder {
        uint8 rarity;
        string cid;
        uint8 nftType;
    }

    struct ReturnMintingOrder {
        uint256 tokenId;
        uint8 rarity;
        string cid;
        uint8 nftType;
    }

    struct TokenDetail {
        uint256 rarity;
        uint8 nftType;
        string tokenURI;
    }

    using Counters for Counters.Counter;
    using CharacterDetails for CharacterDetails.Details;

    event TokenCreated(address to, uint256 tokenId, TokenDetail details);
    event BurnToken(uint256[] ids);
    event SetNewMinter(address newMinter);
    event SetDesign(address designAddress);
    event SetCharacterItem(address itemAddress);
    event SetMarketplace(address marketplaceAddress);
    event AddNewNftType(uint8 nftType, uint8[] rarityList);
    event MintOrder(bytes callbackData, address to, ReturnMintingOrder[] returnMintingOrder);
    event UseNFTs(address to, uint256 amount, uint8 rarity, uint256[] usedTokenIds);
    event SetMaxTokensInOneOrder(uint8 maxTokensInOneOrder);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant OPEN_NFT_ROLE = keccak256("OPEN_NFT_ROLE");

    uint256 private constant maskLast8Bits = uint256(0xff);
    uint256 private constant maskFirst248Bits = ~uint256(0xff);

    // Maketplace contract address => open for setting when in need
    IERC721 public marketPlace;

    // Character Item allow to generate game item NFT from this NFTs
    ICharacterItem public item;

    // Counter for tokenID
    Counters.Counter public tokenIdCounter;

    // Mapping from owner address to list of token IDs.
    mapping(address => uint256[]) public tokenIds;
    mapping(address => (mapping(uint8 => (mapping(uint8 => uint256[]))))) public tokenIdsPerTypeAndRarity;

    // Mapping from token ID to token details.
    mapping(uint256 => TokenDetail) public tokenDetails;


    // Max tokens can mint in one order
    uint8 public MAX_TOKENS_IN_ORDER;

    // Total Supply
    uint256 public totalSupply;

    // Mapping NFT Item from nftType and rarityList
    mapping(uint8 => uint8[]) public nftItems;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    constructor (uint8[] memory _rarityList) {
        MAX_TOKENS_IN_ORDER = 10;
        nftItems[uint8(1)] = _rarityList;
        totalSupply = 100000000;
    }

    /**
     *   Function: Initialized contract
     */
    function initialize() public initializer {
        __ERC721_init("KATANA NFT CHARACTER", "KTNC");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(OPEN_NFT_ROLE, msg.sender);
    }

    /**
     *  @notice Function allow DESIGNER add new NFT type
     */
    function addNewNftType(uint8 _nftType, uint8[] memory _rarityList) external onlyRole(DESIGNER_ROLE) {
        nftItems[_nftType] = _rarityList;
        emit AddNewNftType(_nftType, _rarityList);
    }

    /**
     *  @notice Function allow ADMIN set new wallet is MINTER
     */
    function setMinterRole(address _newMinter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, _newMinter);
        emit SetNewMinter(_newMinter);
    }

    /**
     *  @notice Function allow ADMIN set max tokens per mint
     */
    function setMaxTokensInOneMint(uint8 _maxTokensInOneMint) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_TOKENS_IN_ORDER = _maxTokensInOneMint;
        emit SetMaxTokensInOneOrder(_maxTokensInOneMint);
    }
    
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** 
     *  @notice Burns a list of Characters.
     */
    function burn(uint256[] memory ids) override external onlyRole(BURNER_ROLE) {
        for (uint256 i = 0; i < ids.length; ++i) {
            _burn(ids[i]);
        }
        emit BurnToken(ids);
    }

    /** 
     *  @notice Sets the character item contract address.
     */
    function setItemContract(address contractAddress)
        external
        onlyRole(DESIGNER_ROLE)
    {
        item = ICharacterItem(contractAddress);
        emit SetCharacterItem(contractAddress);
    }

    /** Set marketplace for integrate */
    function setMarketPlace(address contractAddress) external onlyRole(DESIGNER_ROLE) {
        marketPlace = IERC721(contractAddress);
        emit SetMarketplace(contractAddress);
    }

    /** 
     *  @notice Gets token details for the specified owner.
     */
    function getTokenDetailsByOwner(address to)
        external
        view
        returns (TokenDetail[] memory)
    {
        uint256[] storage ids = tokenIds[to];
        TokenDetail[] memory result = new TokenDetail[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            result[i] = tokenDetails[ids[i]];
        }
        return result;
    }

    /** 
     *  @notice Gets token ids for the specified owner.
     */
    function getTokenIdsByOwner(address to)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory ids = tokenIds[to];
        return ids;
    }

    /**
     *  Get total supply of NFTs
     */
    function getTotalSupply() internal view returns (uint256) {
        return totalSupply;
    }

    /**
     *      Get rarity list using in contract
     */
    function getCurrentRarityList() external view returns (uint8[] memory) {
        return rarityList;
    }

    /** 
     *  @notice Creates a token
     */
    function createToken(
        address _to,
        uint8 _rarity,
        string calldata _cid,
        uint8 _nftType
    ) internal returns (uint256){
        // Mint NFT for user "_to"
        tokenIdCounter.increment();
        uint256 _id = tokenIdCounter.current();
        _setTokenUri(_id, _cid);
        _mint(_to, _id);
        
        // Save data for "tokenIds"
        tokenIds[_to].push(_id);

        // Save data for "tokenIdsPerTypeAndRarity"
        tokenIdsPerTypeAndRarity[_to][_nftType][_rarity].push(_id);

        // Save data for "tokenDetails"
        TokenDetail memory _tokenDetail;
        _tokenDetail.rarity = _rarity;
        _tokenDetail.nftType = _nftType;
        _tokenDetail.tokenURI = tokenURI(_id);
        tokenDetails[_id] = _tokenDetail;

        emit TokenCreated(_to, _id, _tokenDetail);
        return uint256(_id);
    }

    /** 
     *  Function mint NFTs
     */
    function mint(
        MintingOrder[] calldata _mintingOrders,
        address _to,
        bytes calldata _callbackData
    ) external notContract onlyRole(MINTER_ROLE) {
        require(_mintingOrders.length > 0, "No token to mint");
        require(_mintingOrders.length <= MAX_TOKENS_IN_ORDER, "Maximum tokens in one mint reached");
        require(
            tokenIdCounter.current() + _mintingOrders.length <= getTotalSupply(),
            "Total supply of NFT reached"
        );  

        for (uint256 i=0; i < _mintingOrders.length; i++) {
            require(_isValidRarity(_mintingOrders[i].rarity, _mintingOrders[i].nftType), "Invalid rarity value");
        }


        ReturnMintingOrder[] memory _returnOrder = new ReturnMintingOrder[](_mintingOrders.length);
        for (uint256 i=0; i < _mintingOrders.length; i++) {
            uint256 _tokenId = createToken(
                _to,
                _mintingOrders[i].rarity,
                _mintingOrders[i].cid,
                _mintingOrders[i].nftType
            );
            _returnOrder[i] = ReturnMintingOrder(
                _tokenId,
                _mintingOrders[i].rarity,
                _mintingOrders[i].cid,
                _mintingOrders[i].nftType
            );
        }

        emit MintOrder(
            _callbackData,
            _to,
            _returnOrder
        );
    }

    /** 
     *      Function return tokenURI for specific NFT 
     *      @param _tokenId ID of NFT
     *      @return tokenURI of token with ID = _tokenId
     */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) { 
        return(tokenDetails[_tokenId].tokenURI);
    }

    /**
     *      Function that gets latest ID of this NFT contract
     *      @return tokenId of latest NFT
     */
    function lastId() public view returns (uint256) {
        return tokenIdCounter.current();
    }

    function _setTokenUri(uint256 _tokenId, string calldata _cid) internal {
        tokenDetails[_tokenId].tokenURI = string(abi.encodePacked("https://", _cid, ".ipfs.w3s.link/"));
    }

    /** Call from CharacterBoxBasket token to open character. */
    function useNFTs(address _to, uint256 _count, uint8 _rarity, uint8 _nftType) external override  onlyRole(OPEN_NFT_ROLE) {
        require(_count > 0, "No token to mint");
        require(tokenIdsPerTypeAndRarity[_to][_nftType][_raity] > count, "User doesn't have enough NFT to call useNFTs");
        require(_isValidRarity(rarity), "Invalid rarity value");
        uint256[] memory _usedTokenIds = new uint256[](count);
        for (uint256 i=0; i < count; i++) {
            uint256[] memory _listToken = tokenIdsPerTypeAndRarity[_to][_nftType][_raity];
            item.createNewItem(_listToken[i]);
            _usedTokenIds[i] = _listToken[i];
        }
        emit UseNFTs(to, count, rarity, _usedTokenIds);
    }

    /**
     *      @notice Check if rarity is valid or not for external call
     */
    function isValidRarity(uint8 _rarity, uint8 _nftType) external view returns (bool) {
        bool isValid = false;
        for (uint256 i=0; i < nftItems[_nftType].length; i++) {
            if (nftItems[_nftType][i] == _rarity) {
                isValid = true;
                break;
            }
        }
        return isValid;
    }

    /** Function check if a rarity is valid rarity value */
    function _isValidRarity(uint8 _rarity, uint8 _nftType) internal view returns (bool) {
        bool isValid = false;
        for (uint256 i=0; i < nftItems[_nftType].length; i++) {
            if (nftItems[_nftType][i] == _rarity) {
                isValid = true;
                break;
            }
        }
        return isValid;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
