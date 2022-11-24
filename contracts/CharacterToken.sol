// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/INFTToken.sol";
import "./interfaces/INftConfigurations.sol";
import "./interfaces/INftFactory.sol";
import "./libraries/CharacterTokenDetails.sol";


contract CharacterToken is
    ERC721Upgradeable,
    IERC721Receiver,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    INFTToken
{
    using Counters for Counters.Counter;
    using CharacterTokenDetails for CharacterTokenDetails.TokenDetail;
    using CharacterTokenDetails for CharacterTokenDetails.MintingOrder;
    using CharacterTokenDetails for CharacterTokenDetails.ReturnMintingOrder;

    event TokenCreated(address to, uint256 tokenId, CharacterTokenDetails.TokenDetail details);
    event BurnToken(uint256[] ids);
    event SetNewMinter(address newMinter);
    event SetCharacterItem(address itemAddress);
    event SetMarketplace(address marketplaceAddress);
    event AddNewNftType(uint8 maxNftType, uint8[] maxRarityList);
    event MintOrderForDev(bytes callbackData, address to, CharacterTokenDetails.ReturnMintingOrder[] returnMintingOrder);
    event MintOrderFromDaapCreator(string callbackData, address to, CharacterTokenDetails.ReturnMintingOrder[] returnMintingOrder);
    event UseNFTs(address to, uint256[] usedTokenIds);
    event SetMaxTokensInOneOrder(uint8 maxTokensInOneOrder);
    event SetMaxTokensInOneUsing(uint8 maxTokenInOneUsing);
    event SetNewMaxRarity(uint8 oldMaxRarity, uint8 newMaxRarity);
    event SetWhiteList(address to);
    event SwitchFreeTransferMode(bool oldMode, bool newMode);
    event UpdateDiableMinting(bool oldState, bool newState);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPEN_BOX_ROLE = keccak256("OPEN_BOX_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant OPEN_NFT_ROLE = keccak256("OPEN_NFT_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    uint256 private constant maskLast8Bits = uint256(0xff);
    uint256 private constant maskFirst248Bits = ~uint256(0xff);

    // Maketplace contract address => open for setting when in need
    IERC721 public marketPlace;

    // Counter for tokenID
    Counters.Counter public tokenIdCounter;

    // Mapping from owner address to list of token IDs.
    mapping(address => uint256[]) public tokenIds;

    // Mapping from token ID to token details.
    mapping(uint256 => CharacterTokenDetails.TokenDetail) public tokenDetails;

    // Max tokens can mint in one order
    uint8 public MAX_TOKENS_IN_ORDER;

    // Max tokens can use in one call
    uint8 public MAX_TOKENS_IN_USING;

    // Total Supply
    uint256 public totalSupply;

    // Mapping address of user and its ability in whitelist or not
    mapping(address => bool) public whiteList;

    // Flag Free transfer NFT
    bool public FREE_TRANSFER;

    // Flag: Enable or disable the feature of minting
    bool public DISABLE_MINTING;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyFromDaapCreator() {
        require(msg.sender == getNftCreator(), "Not be called from Daap Creator");
        _;
    }

    constructor () {
    }

    /**
     *   Function: Initialized contract
     */
    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        _transferOwnership(msg.sender);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(OPEN_NFT_ROLE, msg.sender);
        _setupRole(WHITELIST_ROLE, msg.sender);

        MAX_TOKENS_IN_ORDER = 10;
        MAX_TOKENS_IN_USING = 10;
        totalSupply = 100000000;
        whiteList[msg.sender] = true;
        FREE_TRANSFER = false;
        DISABLE_MINTING = false;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     *      @dev Function allow ADMIN to set user in whitelist
     */
    function setWhiteList(address _to) external onlyRole(DESIGNER_ROLE) {
        whiteList[_to] = true;
        emit SetWhiteList(_to);
    }

    /**
     *      @dev Function allow ADMIN to set free transfer flag
     */
    function switchFreeTransferMode() external onlyRole(DESIGNER_ROLE) {
        bool oldMode = FREE_TRANSFER;
        if (FREE_TRANSFER) {
            FREE_TRANSFER = false;
        } else {
            FREE_TRANSFER = true;
        }
        bool newMode = FREE_TRANSFER;
        emit SwitchFreeTransferMode(oldMode, newMode);
    }

    /**
     *      @notice Funtion switch mode of minting
     */
    function updateDisableMinting(bool _newState) external onlyRole(DESIGNER_ROLE) {
        bool _oldState = DISABLE_MINTING;
        DISABLE_MINTING = _newState;
        emit UpdateDiableMinting(_oldState, _newState);
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

    /**
     *  @notice Function allow ADMIN set max tokens per one use
     */
    function setMaxTokensInOneUsing(uint8 _maxTokenInOneUsing) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_TOKENS_IN_USING = _maxTokenInOneUsing;
        emit SetMaxTokensInOneUsing(_maxTokenInOneUsing);
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
     *  @notice Gets token details for the specified owner.
     */
    function getTokenDetailsByOwner(address to)
        external
        view
        returns (CharacterTokenDetails.TokenDetail[] memory)
    {
        uint256[] storage ids = tokenIds[to];
        CharacterTokenDetails.TokenDetail[] memory result = new CharacterTokenDetails.TokenDetail[](ids.length);
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
     *      @notice Function allow to get token details by token ID
     */
    function getTokenDetailsByID(uint256 _tokenId) external  view returns (CharacterTokenDetails.TokenDetail memory) {
        return tokenDetails[_tokenId];
    }

    /**
     *  Get total supply of NFTs
     */
    function getTotalSupply() internal view returns (uint256) {
        return totalSupply;
    }

    /**
     *  Function mint NFTs order from admin
     */
    function mintOrderForDev(
        CharacterTokenDetails.MintingOrder[] memory _mintingOrders,
        address _to,
        bytes calldata _callbackData
    ) external onlyRole(MINTER_ROLE) {

        CharacterTokenDetails.ReturnMintingOrder[] memory _returnOrder = _mintOneOrder(
            _mintingOrders,
            _to
        );

        emit MintOrderForDev(
            _callbackData,
            _to,
            _returnOrder
        );
    }

    /**
     *  Function mint NFTs order from daap creator
     */
    function mintOrderFromDaapCreator(
        CharacterTokenDetails.MintingOrder[] memory _mintingOrders,
        address _to,
        string calldata _callbackData
    ) external onlyFromDaapCreator {

        CharacterTokenDetails.ReturnMintingOrder[] memory _returnOrder = _mintOneOrder(
            _mintingOrders,
            _to
        );

        emit MintOrderFromDaapCreator(
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

    /**
     *      @notice Function that override "_transfer" function default of ERC721 upgradeable
     *      @dev Check token using or not
     *      @dev Can not be transfer after using
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (FREE_TRANSFER == false) {
            require(
                whiteList[to] == true || whiteList[from],
                "Not support to transfer directly"
            );
        }
        ERC721Upgradeable._transfer(from, to, tokenId);
    }

    function _setTokenUri(
        uint256 _tokenId,
        uint256 _rarity,
        uint256 _meshIndex,
        uint256 _meshMaterial
    ) internal {
        string memory _cid = INftConfigurations(getNftConfigurations()).getCid(
            _rarity,
            _meshIndex,
            _meshMaterial
        );
        tokenDetails[_tokenId].tokenURI = string(abi.encodePacked("https://", _cid, ".ipfs.w3s.link/"));
    }

    /**
     *      @notice Internal function allow to mint an order of minting list of NFTs
     */
    function _mintOneOrder(
        CharacterTokenDetails.MintingOrder[] memory _mintingOrders,
        address _to
    ) internal returns(CharacterTokenDetails.ReturnMintingOrder[] memory) {
        require(_mintingOrders.length > 0, "No token to mint");
        require(_mintingOrders.length <= MAX_TOKENS_IN_ORDER, "Maximum tokens in one mint reached");
        require(
            tokenIdCounter.current() + _mintingOrders.length <= getTotalSupply(),
            "Total supply of NFT reached"
        );

        for (uint256 i=0; i < _mintingOrders.length; i++) {
            require(
                INftConfigurations(getNftConfigurations()).checkValidMintingAttributes(
                    address(this),
                    _mintingOrders[i]
                ),
                "Invalid rarity"
            );
        }

        CharacterTokenDetails.ReturnMintingOrder[] memory _returnOrder = new CharacterTokenDetails.ReturnMintingOrder[](_mintingOrders.length);
        for (uint256 i=0; i < _mintingOrders.length; i++) {
            uint256 _tokenId = createToken(
                _to,
                _mintingOrders[i]
            );
            _returnOrder[i] = CharacterTokenDetails.ReturnMintingOrder(
                _tokenId,
                _mintingOrders[i]
            );
        }
        return _returnOrder;
    }

    /**
     *  @notice Creates a token only for normal minting action
     */
    function createToken(
        address _to,
        CharacterTokenDetails.MintingOrder memory _mintingOrder
    ) internal returns (uint256){
        // Mint NFT for user "_to"
        tokenIdCounter.increment();
        uint256 _id = tokenIdCounter.current();
        _setTokenUri(
            _id,
            _mintingOrder.rarity,
            _mintingOrder.meshIndex,
            _mintingOrder.meshMaterial
        );
        _mint(_to, _id);

        // // Save data for "tokenIds"
        // tokenIds[_to].push(_id);

        // Save data for "tokenDetails"
        CharacterTokenDetails.TokenDetail memory _tokenDetail;
        _tokenDetail.mintingOrder = _mintingOrder;
        _tokenDetail.tokenURI = tokenURI(_id);
        tokenDetails[_id] = _tokenDetail;

        emit TokenCreated(_to, _id, _tokenDetail);
        return uint256(_id);
    }

    /**
     *      @notice Function checking before transfer action occurs
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override {
        if (from == address(0)) {
            // Mint.
        } else {
            // Transfer or burn.

            // Pop tokenID out of list of user #"from": tokenIds
            uint256[] storage ids = tokenIds[from];
            uint256 index;
            for (uint256 i=0; i < ids.length; i++) {
                if (ids[i] == id) {
                    index = i;
                    break;
                }
            }
            ids[index] = ids[ids.length - 1];

            ids.pop();
        }
        if (to == address(0)) {
            // Burn.
            delete tokenDetails[id];
        } else {
            // Transfer or mint.
            // Push new tokenID into list of user #"to": tokenIds
            uint256[] storage ids = tokenIds[to];
            ids.push(id);
        }
    }

    /**
     *  @notice Function internal getting the address of NFT creator
     */
    function getNftCreator() internal view returns(address) {
        return INftFactory(owner()).getCurrentDappCreatorAddress();
    }

    /**
     *  @notice Function internal returns the address of NftConfigurations
     */
    function getNftConfigurations() internal view returns(address) {
        return INftFactory(owner()).getCurrentNftConfigurations();
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
