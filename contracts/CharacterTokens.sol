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
import "./interfaces/ICharacterDesign.sol";
import "./interfaces/INFTToken.sol";


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
    }

    struct ReturnMintingOrder {
        uint256 tokenId;
        uint8 rarity;
        string cid;
    }

    struct CreateTokenRequest {
        string orderId;
        address recipient;
    }

    struct TokenDetail {
        uint256 rarity;
        string tokenURI;
    }

    using Counters for Counters.Counter;
    using CharacterDetails for CharacterDetails.Details;

    event TokenCreated(address to, uint256 tokenId, TokenDetail details);
    event BurnToken(uint256[] ids);
    event SetNewMinter(address newMinter);
    event SetDesign(address designAddress);
    event SetMarketplace(address marketplaceAddress); 
    event MintOrder(string orderId, address to, ReturnMintingOrder[] returnMintingOrder);
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

    // Design of NFT => open for setting when in need
    ICharacterDesign public design;

    // Counter for tokenID
    Counters.Counter public tokenIdCounter;

    // Mapping from owner address to list of token IDs.
    mapping(address => uint256[]) public tokenIds;

    // Mapping from token ID to token details.
    mapping(uint256 => TokenDetail) public tokenDetails;

    // Mapping from dev wallet address to its minting nft requests.
    CreateTokenRequest[] public createTokenRequests;

    // Max tokens can mint in one order
    uint8 public MAX_TOKENS_IN_ORDER;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    constructor () public {
        MAX_TOKENS_IN_ORDER = 10;
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

    function setMinterRole(address _newMinter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, _newMinter);
        emit SetNewMinter(_newMinter);
    }

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

    /** Burns a list of Characters. */
    function burn(uint256[] memory ids) override external onlyRole(BURNER_ROLE) {
        for (uint256 i = 0; i < ids.length; ++i) {
            _burn(ids[i]);
        }
        emit BurnToken(ids);
    }

    /** Sets the design. */
    function setDesign(address contractAddress)
        external
        onlyRole(DESIGNER_ROLE)
    {
        design = ICharacterDesign(contractAddress);
        emit SetDesign(contractAddress);
    }

    function setMarketPlace(address contractAddress) external onlyRole(DESIGNER_ROLE) {
        marketPlace = IERC721(contractAddress);
        emit SetMarketplace(contractAddress);
    }

    /** Gets token details for the specified owner. */
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

    /** Gets token ids for the specified owner. */
    function getTokenIdsByOwner(address to)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory ids = tokenIds[to];
        return ids;
    }

    /** Creates a token */
    function createToken(
        address _to,
        uint8 _rarity,
        string calldata _cid
    ) internal returns (uint256){
        uint256 _id = tokenIdCounter.current();
        TokenDetail memory _tokenDetail;
        _tokenDetail.rarity = _rarity;
        _setTokenUri(_id, _cid);
        tokenDetails[_id] = _tokenDetail;
        _mint(_to, _id);
        tokenIdCounter.increment();
        emit TokenCreated(_to, _id, _tokenDetail);
        return uint256(_id);
    }

    /** 
     *  Function mint a single NFT from BE
     *
     */
    function mint(
        MintingOrder[] calldata _mintingOrders,
        address _to,
        string calldata _orderId
    ) external notContract onlyRole(MINTER_ROLE) {
        require(_mintingOrders.length > 0, "No token to mint");
        require(_mintingOrders.length <= MAX_TOKENS_IN_ORDER, "Maximum tokens in one mint reached");
        require(
            tokenIdCounter.current() + _mintingOrders.length <= design.getTotalSupply(),
            "Total supply of NFT reached"
        );  

        uint256[] memory _returnOrder = new ReturnMintingOrder[](_mintingOrders.length);
        for (uint256 i=0; i < _mintingOrders.length; i++) {
            uint256 _tokenId = createToken(
                _to,
                _mintingOrders[i].rarity,
                _mintingOrders[i].cid
            );
            _returnOrder[i] = ReturnMintingOrder(
                _tokenId,
                _mintingOrders[i].rarity,
                _mintingOrders[i].cid
            );
        }

        // Create record of orders minting NFTs 
        createTokenRequests.push(
            CreateTokenRequest(
                _orderId,
                _to
            )
        );

        emit MintOrder(
            _orderId,
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
    function useNFTs(address to, uint256 count, uint8 rarity) external override  onlyRole(OPEN_NFT_ROLE) {
        require(count > 0, "No token to mint");
        require(tokenIds[to].length > count, "User doesn't have enough NFT to call useNFTs");
        require(rarity > 0 && rarity < design.lastRarityId(), "Rarity invalid");
        uint256[] memory _usedTokenIds = new uint256[](count);
        for (uint256 i=0; i < count; i++) {
            uint256[] memory _listToken = tokenIds[to];
            design.createNewDesign(_listToken[i]);
            _usedTokenIds[i] = _listToken[i];
        }
        emit UseNFTs(to, count, rarity, _usedTokenIds);
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
