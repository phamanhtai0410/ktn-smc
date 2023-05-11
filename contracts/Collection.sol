// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IConfiguration.sol";
import "./interfaces/IFactory.sol";

contract KatanaInuCollection is
    ERC721Upgradeable,
    IERC721Receiver,
    OwnableUpgradeable,
    ERC721RoyaltyUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;

    struct ReturnMintingOrder {
        uint256 nftIndex;
        uint256 tokenId;
    }

    event TokenCreated(address to, uint256 tokenId, uint256 nftIndex);
    event BurnToken(uint256[] ids);
    event SetNewMinter(address newMinter);
    event MintOrderForDev(
        bytes callbackData,
        address to,
        ReturnMintingOrder[] returnMintingOrder
    );
    event MintOrderFromDaapCreator(
        string callbackData,
        address to,
        ReturnMintingOrder[] returnMintingOrder
    );
    event SetMaxTokensInOneOrder(uint8 maxTokensInOneOrder);
    event SetMaxTokensInOneUsing(uint8 maxTokenInOneUsing);
    event SwitchFreeTransferMode(bool oldMode, bool newMode);
    event UpdateDiableMinting(bool oldState, bool newState);
    event NewLimitation(uint256 oldLimitation, uint256 newLimitation);

    bytes32 public constant OPEN_BOX_ROLE = keccak256("OPEN_BOX_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Counter for tokenID
    Counters.Counter public tokenIdCounter;

    // Mapping from owner address to list of token IDs.
    mapping(address => uint256[]) public tokenIds;

    // Max tokens can mint in one order
    uint8 public MAX_TOKENS_IN_ORDER;

    // Total Supply
    uint256 public totalSupply;

    // The limitation of the minting
    uint256 public limitation;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyFromDaapCreator() {
        require(
            msg.sender == getNftCreator(),
            "Not be called from Daap Creator"
        );
        _;
    }

    /**
     *   Function: Initialized contract
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Ownable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        MAX_TOKENS_IN_ORDER = 10;
        totalSupply = _totalSupply;
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
     * Function allow DESIGNER to re-config the total supply of colleciton
     * @param _newLimitation new value to reconfig
     */
    function setTheLimitation(
        uint256 _newLimitation
    ) external onlyRole(DESIGNER_ROLE) {
        require(
            _newLimitation != limitation,
            "new-limitation-muste-be-different"
        );
        require(
            _newLimitation <= totalSupply,
            "The-limitation-must-be-smaller-than-total-supply"
        );
        uint256 oldLimitation = limitation;
        limitation = _newLimitation;
        emit NewLimitation(oldLimitation, _newLimitation);
    }

    /**
     *  @notice Function allow ADMIN set new wallet is MINTER
     */
    function setMinterRole(
        address _newMinter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, _newMinter);
        emit SetNewMinter(_newMinter);
    }

    /**
     *  @notice Function allow ADMIN set max tokens per mint
     */
    function setMaxTokensInOneMint(
        uint8 _maxTokensInOneMint
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_TOKENS_IN_ORDER = _maxTokensInOneMint;
        emit SetMaxTokensInOneOrder(_maxTokensInOneMint);
    }

    /**
     * @dev Function allows ADMIN ROLE to config the default royalty fee
     */
    function configRoyalty(
        address _wallet,
        uint96 _rate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._setDefaultRoyalty(_wallet, _rate);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            AccessControlUpgradeable,
            ERC721RoyaltyUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /**
     *  @notice Burns a list of Characters.
     */
    function burn(uint256[] memory ids) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < ids.length; ++i) {
            _burn(ids[i]);
        }
        emit BurnToken(ids);
    }

    /**
     *  @notice Gets token ids for the specified owner.
     */
    function getTokenIdsByOwner(
        address to
    ) external view returns (uint256[] memory) {
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
     *  Function mint NFTs order from daap creator
     */
    function mint(
        uint256[] memory _nftIndexes,
        address _to,
        string calldata _callbackData
    ) external onlyFromDaapCreator {
        ReturnMintingOrder[] memory _returnOrder = _mintOneOrder(
            _nftIndexes,
            _to
        );
        emit MintOrderFromDaapCreator(_callbackData, _to, _returnOrder);
    }

    /**
     *  Function mint NFTs order from admin
     */
    function mintOwner(
        uint256[] memory _nftIndexes,
        address _to,
        bytes calldata _callbackData
    ) external onlyRole(MINTER_ROLE) {
        ReturnMintingOrder[] memory _returnOrder = _mintOneOrder(
            _nftIndexes,
            _to
        );

        emit MintOrderForDev(_callbackData, _to, _returnOrder);
    }

    /**
     *      Function return tokenURI for specific NFT
     *      @param _tokenId ID of NFT
     *      @return tokenURI of token with ID = _tokenId
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return
            IConfiguration(getNftConfigurations()).getCollectionURI(
                address(this),
                _tokenId
            );
    }

    /**
     *      Function that gets latest ID of this NFT contract
     *      @return tokenId of latest NFT
     */
    function lastId() public view returns (uint256) {
        return tokenIdCounter.current();
    }

    /**
     *      @notice Internal function allow to mint an order of minting list of NFTs
     */
    function _mintOneOrder(
        uint256[] memory _nftIndexes,
        address _to
    ) internal returns (ReturnMintingOrder[] memory) {
        require(_nftIndexes.length > 0, "No token to mint");
        require(
            _nftIndexes.length <= MAX_TOKENS_IN_ORDER,
            "Maximum tokens in one mint reached"
        );
        require(
            tokenIdCounter.current() + _nftIndexes.length <= limitation,
            "The limitation of minting reached"
        );
        require(
            tokenIdCounter.current() + _nftIndexes.length <= getTotalSupply(),
            "Total supply of NFT reached"
        );

        for (uint256 i = 0; i < _nftIndexes.length; i++) {
            require(
                IConfiguration(getNftConfigurations())
                    .checkValidMintingAttributes(address(this), _nftIndexes[i]),
                "Invalid NFT index"
            );
        }

        ReturnMintingOrder[] memory _returnOrder = new ReturnMintingOrder[](
            _nftIndexes.length
        );
        for (uint256 i = 0; i < _nftIndexes.length; i++) {
            uint256 _tokenId = createToken(_to, _nftIndexes[i]);
            _returnOrder[i] = ReturnMintingOrder(_tokenId, _nftIndexes[i]);
        }
        return _returnOrder;
    }

    /**
     *  @notice Creates a token only for normal minting action
     */
    function createToken(
        address _to,
        uint256 _nftIndex
    ) internal returns (uint256) {
        // Mint NFT for user "_to"
        tokenIdCounter.increment();
        uint256 _id = tokenIdCounter.current();
        _mint(_to, _id);
        emit TokenCreated(_to, _id, _nftIndex);
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
            for (uint256 i = 0; i < ids.length; i++) {
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
    function getNftCreator() internal view returns (address) {
        return IFactory(owner()).getCurrentDappCreatorAddress();
    }

    /**
     *  @notice Function internal returns the address of NftConfigurations
     */
    function getNftConfigurations() internal view returns (address) {
        return IFactory(owner()).getCurrentConfiguration();
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
