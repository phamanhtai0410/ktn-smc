// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "./libraries/BoxDetails.sol";
import "./libraries/Utils.sol";
import "./interfaces/ICollection.sol";
import "./interfaces/IConfiguration.sol";
import "./interfaces/IFactory.sol";

contract KatanaInuBox is
    ERC721Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IERC721Receiver,
    ERC721RoyaltyUpgradeable
{
    using Counters for Counters.Counter;
    using BoxDetails for BoxDetails.BoxDetail;

    struct CreateBoxRequest {
        uint256 targetBlock; // Use future block.
        uint16 count; // Amount of tokens to mint.
    }

    event TokenCreated(
        address to,
        uint256 tokenId,
        BoxDetails.BoxDetail details
    );
    event MintOrderForDev(
        bytes callbackData,
        address to,
        BoxDetails.BoxDetail[] returnMintingOrder
    );
    event MintOrderFromDaapCreator(
        string callbackData,
        address to,
        BoxDetails.BoxDetail[] returnMintingOrder
    );
    event OpenBox(address to, uint256[] tokenIds);
    event SendNft(address from, address to, uint256 tokenId);
    event ProcessBoxOpeningRequests(address to);
    event BoxOpeningRequested(address to, uint256 targetBlock);
    event SetNewMinter(address newMinter);

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant maskLast8Bits = uint256(0xff);
    uint256 private constant maskFirst248Bits = ~uint256(0xff);

    uint public constant COIN_DECIMALS = 10 ** 18;

    uint256 public TOTAL_BOX;
    uint256 public MAX_OPEN_BOX_UNIT;

    Counters.Counter public tokenIdCounter;
    // Box Metadata URI
    string public tokenUri;

    // Limit each common user to by.
    uint256 public boxLimit;

    // Mapping addresses to buyable amount
    mapping(address => uint256) public boughtList;

    // Mapping from owner address to token ID.
    mapping(address => uint256[]) public tokenIds;

    // Mapping from token ID to token details.
    mapping(uint256 => BoxDetails.BoxDetail) public tokenDetails;

    // Mapping from owner address to Box token requests.
    mapping(address => CreateBoxRequest[]) public boxRequests;

    // Whitelist Blacklist
    mapping(address => bool) public blackList;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyFromBoxCreator() {
        require(
            msg.sender == getCreator(),
            "Not be called from Box NFT Creator"
        );
        _;
    }

    constructor() {}

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _totalSupply
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);

        tokenUri = _tokenURI;
        TOTAL_BOX = _totalSupply;
        MAX_OPEN_BOX_UNIT = 5;
        // Limit box each user can mint
        boxLimit = 3;
        _transferOwnership(msg.sender);
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

    /** Burns a list of pets. */
    function burn(uint256[] memory ids) external onlyRole(BURNER_ROLE) {
        for (uint256 i = 0; i < ids.length; ++i) {
            _burn(ids[i]);
        }
    }

    /** Set boxLimit. */
    function setBoxLimit(uint256 boxLimit_) external onlyRole(DESIGNER_ROLE) {
        boxLimit = boxLimit_;
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

    /** Set total box minted. */
    function setTotalBox(uint256 totalBox_) external onlyRole(DESIGNER_ROLE) {
        TOTAL_BOX = totalBox_;
    }

    /** Set max number for each open box. */
    function setMaxOpenBox(uint256 maxOpen_) external onlyRole(DESIGNER_ROLE) {
        MAX_OPEN_BOX_UNIT = maxOpen_;
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
     *      Function return tokenURI for specific NFT
     *      @param _tokenId ID of NFT
     *      @return tokenURI of token with ID = _tokenId
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "token-id-not-exist");
        return tokenUri;
    }

    function getBoxIdsByOwner(
        address owner
    ) external view returns (uint256[] memory) {
        uint256[] memory ids = tokenIds[owner];
        return ids;
    }

    function getBoxByOwner(
        address owner
    ) external view returns (BoxDetails.BoxDetail[] memory) {
        uint256[] memory ids = tokenIds[owner];
        BoxDetails.BoxDetail[] memory boxs = new BoxDetails.BoxDetail[](
            ids.length
        );
        for (uint256 i = 0; i < ids.length; ++i) {
            BoxDetails.BoxDetail memory boxDetail = tokenDetails[ids[i]];
            boxs[i] = boxDetail;
        }
        return boxs;
    }

    function getOpenableBoxByOwner(
        address owner
    ) external view returns (BoxDetails.BoxDetail[] memory) {
        uint256[] memory ids = tokenIds[owner];
        BoxDetails.BoxDetail[] memory boxs = new BoxDetails.BoxDetail[](
            ids.length
        );
        for (uint256 i = 0; i < ids.length; ++i) {
            BoxDetails.BoxDetail memory boxDetail = tokenDetails[ids[i]];
            if (boxDetail.is_opened == false) {
                boxs[i] = boxDetail;
            }
        }
        return boxs;
    }

    /**
     *  Function mint NFTs Box from admin
     */
    function mintOrderForDev(
        uint256 _count,
        address _to,
        bytes calldata _callbackData
    ) external onlyRole(MINTER_ROLE) {
        BoxDetails.BoxDetail[] memory _boxDetails = _mintOneOrder(_count, _to);
        emit MintOrderForDev(_callbackData, _to, _boxDetails);
    }

    /**
     *  Function mint NFTs order from daap creator
     */
    function mintBoxFromDaapCreator(
        uint256 _count,
        bool _isWhitelistMint,
        address _to,
        string memory _callbackData
    ) external onlyFromBoxCreator {
        if (_isWhitelistMint) {
            require(!blackList[_to], "Whitelist slot's already used");
        }
        require(_count > 0, "No token to mint");
        require(tokenIdCounter.current() + _count <= TOTAL_BOX, "Box sold out");
        // Check limit.
        address to = msg.sender;
        require(boughtList[to] + _count <= boxLimit, "User limit buy reached");
        BoxDetails.BoxDetail[] memory _boxDetails = _mintOneOrder(_count, _to);
        boughtList[_to] = boughtList[_to] + _count;

        if (_isWhitelistMint) {
            blackList[_to] = true;
        }

        emit MintOrderFromDaapCreator(_callbackData, _to, _boxDetails);
    }

    function _mintOneOrder(
        uint256 _count,
        address _to
    ) internal returns (BoxDetails.BoxDetail[] memory) {
        BoxDetails.BoxDetail[] memory _returnOrder = new BoxDetails.BoxDetail[](
            _count
        );
        for (uint256 i = 0; i < _returnOrder.length; ++i) {
            uint256 id = tokenIdCounter.current();
            tokenIdCounter.increment();
            BoxDetails.BoxDetail memory boxDetail;
            boxDetail.id = id;
            boxDetail.index = i;
            boxDetail.owner_by = _to;
            tokenDetails[id] = boxDetail;
            _safeMint(_to, id);
            _returnOrder[i] = BoxDetails.BoxDetail(id, i, false, _to);
            emit TokenCreated(_to, id, boxDetail);
        }
        return _returnOrder;
    }

    /** Open multiple Boxes NFT. */
    function openBoxes(uint256[] calldata tokenIds_) external notContract {
        address to = msg.sender;
        require(
            tokenIds_.length <= MAX_OPEN_BOX_UNIT,
            "Open over maximun boxs each time."
        );
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            BoxDetails.BoxDetail memory boxDetail = tokenDetails[tokenIds_[i]];
            require(boxDetail.owner_by == to, "Token not owned");
            require(boxDetail.is_opened == false, "Box already opened");
        }
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            BoxDetails.BoxDetail storage boxDetail = tokenDetails[tokenIds_[i]];
            boxDetail.is_opened = true;
        }
        // Add open Box request
        addBoxOpenRequest(to, tokenIds_.length);
        emit OpenBox(to, tokenIds_);
    }

    /**
     *  @notice Function add Box opening request
     */
    function addBoxOpenRequest(address to, uint256 count) internal {
        uint256 targetBlock = block.number + 5;
        boxRequests[to].push(CreateBoxRequest(targetBlock, uint16(count)));
        emit BoxOpeningRequested(to, targetBlock);
    }

    /**
     *  @notice Function is used to get the amount of pending NFTs that needs to open from Box of one wallet at the moment
     *  @param to Address of user need to check
     */
    function getPendingNfts(address to) external view returns (uint256) {
        uint256 result;
        CreateBoxRequest[] storage requests = boxRequests[to];
        for (uint256 i = 0; i < requests.length; ++i) {
            CreateBoxRequest storage request = requests[i];
            if (block.number > request.targetBlock) {
                result += request.count;
            } else {
                break;
            }
        }
        return result;
    }

    /**
     *  @notice Function is used to get total processable of NFTs that can be process
     */
    function getProcessableTokens(address to) external view returns (uint256) {
        uint256 result;
        CreateBoxRequest[] storage requests = boxRequests[to];
        for (uint256 i = 0; i < requests.length; ++i) {
            result += requests[i].count;
        }
        return result;
    }

    /**
     *  @notice Function that call from FE to process Box Opening action
     */
    function processBoxOpeningRequests() external notContract {
        address to = msg.sender;

        CreateBoxRequest[] storage requests = boxRequests[to];
        for (uint256 i = requests.length; i > 0; --i) {
            // Trigger to each request
            CreateBoxRequest storage request = requests[i - 1];

            // Get data from request
            uint256 targetBlock = request.targetBlock;
            uint256 count = request.count;

            // Check targetBlock reach or not
            require(block.number > targetBlock, "Target block not arrived");

            // Hash current executed block
            uint256 seed = uint256(blockhash(targetBlock));

            if (seed == 0) {
                targetBlock =
                    (block.number & maskFirst248Bits) +
                    (targetBlock & maskLast8Bits);
                if (targetBlock >= block.number) {
                    targetBlock -= 256;
                }
                seed = uint256(blockhash(targetBlock));
            }
            // Execute minting action to NFT contract
            executeOneBoxOpening(to, count, seed);
            requests.pop();
        }
        emit ProcessBoxOpeningRequests(to);
    }

    /**
     *  @notice Function's used to execute mint NFT in NFT collection contract
     */
    function executeOneBoxOpening(
        address to,
        uint256 count,
        uint256 seed
    ) internal {
        uint256 nextSeed = seed;
        uint256[] memory _randomNumbers = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            uint256 _currId = ICollection(getOpeningCollection(address(this)))
                .lastId();

            uint256 _maxIndex = IConfiguration(getConfiguration())
                .getMaxIndexOfBox(address(this));
            uint256 tokenSeed = uint256(
                keccak256(abi.encode(nextSeed, _currId))
            );
            uint256 result;
            (nextSeed, result) = Utils.randomRange(tokenSeed, 0, _maxIndex);
            _currId += 1;
            _randomNumbers[i] = result;
        }
        ICollection(getOpeningCollection(address(this))).mintFromBoxOpening(
            _randomNumbers,
            to
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        BoxDetails.BoxDetail storage boxDetail = tokenDetails[tokenId];
        require(boxDetail.is_opened == false, "Box already opened");

        if (from == address(this)) {
            boxDetail.owner_by = to;
        }

        if (from != address(this) && to != address(this)) {
            boxDetail.owner_by = to;
        }

        ERC721Upgradeable._transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override {
        if (from == address(0)) {
            // Mint.
        } else {
            // Transfer or burn.
            // Swap and pop.
            uint256[] storage ids = tokenIds[from];
            BoxDetails.BoxDetail storage boxDetail = tokenDetails[id];
            uint256 index = boxDetail.index;
            // Assign lastId to index to pop lastId.
            uint256 lastId = ids[ids.length - 1];
            ids[index] = lastId;
            ids.pop();

            // Update index after assign boxDetail to new index.
            BoxDetails.BoxDetail storage boxDetailLastId = tokenDetails[lastId];
            boxDetailLastId.index = index;
        }
        if (to == address(0)) {
            // Burn.
            delete tokenDetails[id];
        } else {
            // Transfer or mint.
            uint256[] storage ids = tokenIds[to];
            uint256 index = ids.length;
            ids.push(id);
            // Update index of boxDetail after push to the end of new user array
            BoxDetails.BoxDetail storage boxDetail = tokenDetails[id];
            boxDetail.index = index;
            require(boxDetail.is_opened == false, "Box already opened");
        }
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
     *  @notice Function internal for getting current boxConfigurations address
     *  @dev owner of each box is the box factory
     */
    function getConfiguration() internal view returns (address) {
        return IFactory(owner()).getCurrentConfiguration();
    }

    /**
     *  @notice Function internal for getting current boxCreator address
     *  @dev owner of each box is the box factory
     */
    function getCreator() internal view returns (address) {
        return IFactory(owner()).getCurrentDappCreatorAddress();
    }

    /**
     *  @notice Function internal for getting NFT collection address
     *  @dev Owner is Box Factory
     */
    function getOpeningCollection(
        address _boxAddress
    ) internal returns (address) {
        return IFactory(owner()).getOpeningCollectionOfBox(_boxAddress);
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
