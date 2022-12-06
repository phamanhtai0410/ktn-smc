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
import "./libraries/BoxNFTDetails.sol";
import "./libraries/CharacterTokenDetails.sol";
import "./Utils.sol";
import "./interfaces/INFTToken.sol";
import "./interfaces/IBoxNFTCreator.sol";
import "./interfaces/IBoxesConfigurations.sol";
import "./interfaces/ICharacterToken.sol";
import "./interfaces/IBoxFactory.sol";


contract MysteryBoxNFT is
    ERC721Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IERC721Receiver
    {
    using BoxNFTDetails for BoxNFTDetails.BoxNFTDetail;
    using Counters for Counters.Counter;
    using CharacterTokenDetails for CharacterTokenDetails.MintingOrder;

    struct CreateBoxRequest {
        uint256 targetBlock;    // Use future block.
        uint16 count;           // Amount of tokens to mint.
    }

    event TokenCreated(address to, uint256 tokenId, BoxNFTDetails.BoxNFTDetail details);
    event MintOrderForDev(bytes callbackData, address to, BoxNFTDetails.BoxNFTDetail[] returnMintingOrder);
    event MintOrderFromDaapCreator(string callbackData, address to, BoxNFTDetails.BoxNFTDetail[] returnMintingOrder);
    event OpenBox(address to, uint256[] tokenIds);
    event SendNft(address from, address to, uint256 tokenId);
    event ProcessBoxOpeningRequests(address to);
    event BoxOpeningRequested(address to, uint256 targetBlock);

    // event GetRates(uint256[] rates);
    // event NewIndex(uint256 newIndex);
    // event CurrID(uint256 currID);
    // event Final(CharacterTokenDetails.MintingOrder[] _finally);
    
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
    IERC20 public coinToken;

    Counters.Counter public tokenIdCounter;
    
    // Limit each common user to by.
    uint256 public boxLimit;
    bool public buyable;

    // Total boxes in whitelist pool
    uint256 public whiteListPool;
    uint256 public whiteListBought;

    // Mapping whitelist addresses to buyable amount
    mapping(address => uint256) public whiteList;

    // Mapping addresses to buyable amount
    mapping(address => uint256) public boughtList;

    // Mapping from owner address to token ID.
    mapping(address => uint256[]) public tokenIds;

    // Mapping from token ID to token details.
    mapping(uint256 => BoxNFTDetails.BoxNFTDetail) public tokenDetails;

    // Mapping from owner address to Box token requests.
    mapping(address => CreateBoxRequest[]) public boxRequests;

    /**
        * @notice Checks if the msg.sender is a contract or a proxy
    */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyFromBoxCreator() {
        require(msg.sender == getBoxCreator(), "Not be called from Box NFT Creator");
        _;
    }

    constructor () {
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20 _coinToken
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(WHITELIST_ROLE, msg.sender);
        
        coinToken = _coinToken;
        TOTAL_BOX = 10000;
        MAX_OPEN_BOX_UNIT = 5;
        // Limit box each user can mint
        boxLimit = 3;
        _transferOwnership(msg.sender);
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

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        coinToken.transfer(msg.sender, coinToken.balanceOf(address(this)));
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


    function _setTokenUri(
        uint256 _tokenId
    ) internal {
        string memory _cid = IBoxesConfigurations(getBoxConfigurations()).getCid();
        tokenDetails[_tokenId].tokenURI = string(abi.encodePacked("https://", _cid, ".ipfs.w3s.link/"));
    }

    function _getTokenUri() internal returns(string memory _cid) {
        _cid = IBoxesConfigurations(getBoxConfigurations()).getCid();
    }

    /** Set total box minted. */
    function setTotalBox(uint256 totalBox_) external onlyRole(DESIGNER_ROLE) {
        TOTAL_BOX = totalBox_;
    }

    /** Set max number for each open box. */
    function setMaxOpenBox(uint256 maxOpen_) external onlyRole(DESIGNER_ROLE) {
        MAX_OPEN_BOX_UNIT = maxOpen_;
    }

    /** Enable common user mint box */
    function setBuyable(bool isBuyable) external onlyRole(DESIGNER_ROLE) {
        buyable = isBuyable;
    }
    
    /**
     *      Function return tokenURI for specific NFT
     *      @param _tokenId ID of NFT
     *      @return tokenURI of token with ID = _tokenId
     */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return(tokenDetails[_tokenId].tokenURI);
    }

    /** Set whitelist addresses and amount.
    If set after addr whitelistMint tokens, amount will be reset to input amount. */
    function setWhitelist(address addr, uint256 amount) external onlyRole(WHITELIST_ROLE) {
        whiteList[addr] = amount;
        // If owner add addr to whitelist multiple time, whiteListPool will increase multiple time.
        whiteListPool += amount;
    }

    function getBoxIdsByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory ids = tokenIds[owner];
        return ids;
    }

    function getBoxByOwner(address owner)
        external
        view
        returns (BoxNFTDetails.BoxNFTDetail[] memory)
    {
        uint256[] memory ids = tokenIds[owner];
        BoxNFTDetails.BoxNFTDetail[] memory boxs = new BoxNFTDetails.BoxNFTDetail[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            BoxNFTDetails.BoxNFTDetail memory boxDetail = tokenDetails[ids[i]];
            boxs[i] = boxDetail;
        }
        return boxs;
    }

    function getOpenableBoxByOwner(address owner)
        external
        view
        returns (BoxNFTDetails.BoxNFTDetail[] memory)
    {
        uint256[] memory ids = tokenIds[owner];
        BoxNFTDetails.BoxNFTDetail[] memory boxs = new BoxNFTDetails.BoxNFTDetail[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            BoxNFTDetails.BoxNFTDetail memory boxDetail = tokenDetails[ids[i]];
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
        require(buyable == true, "Mint token have not start yet");
        BoxNFTDetails.BoxNFTDetail[] memory _boxDetails = _mintOneOrder(
            _count,
            _to
        );
        emit MintOrderForDev(
            _callbackData,
            _to,
            _boxDetails
        );
    }
    
    /** 
     *  Function mint NFTs order from daap creator
     */
    function mintBoxFromDaapCreator(
        uint256 _count,
        address _to,
        string calldata _callbackData
    ) external onlyFromBoxCreator {
        require(_count > 0, "No token to mint");
        require(tokenIdCounter.current() + _count <= TOTAL_BOX, "Box sold out");
        // Check limit.
        address to = msg.sender;
        require(boughtList[to] + _count <= boxLimit, "User limit buy reached");
        require(buyable == true, "Mint token have not start yet");
        BoxNFTDetails.BoxNFTDetail[] memory _boxDetails = _mintOneOrder(
            _count,
            _to
        );
        boughtList[_to] = boughtList[_to] + _count;
        emit MintOrderFromDaapCreator(
            _callbackData,
            _to,
            _boxDetails
        );
    }

    /** Whitelist mint tokens.*/
    function whitelistMint(uint256 count) external notContract {
        require(count > 0, "No token to mint");
        address to = msg.sender;
        require(whiteList[to] >= count, "User not in whitelist or limit reached");
        require(tokenIdCounter.current() + count <= TOTAL_BOX, "Box sold out");
        ( , , uint256 _boxPrice) = IBoxesConfigurations(getBoxConfigurations()).getBoxInfos(address(this));
        address owner = address(this);
        string memory _tokenURI = _getTokenUri();
        // Transfer token
        coinToken.transferFrom(to, owner, _boxPrice * count);
        whiteList[to] -= count;
        for (uint256 i = 0; i < count; ++i) {
            uint256 id = tokenIdCounter.current();
            tokenIdCounter.increment();
            BoxNFTDetails.BoxNFTDetail memory boxDetail;
            boxDetail.id = id;
            boxDetail.index = i;
            boxDetail.owner_by = to;
            boxDetail.tokenURI = _tokenURI;
            tokenDetails[id] = boxDetail;
            _safeMint(to, id);
            emit TokenCreated(to, id, boxDetail);
        }
        whiteListBought += count;
    }

    // Owner mint without transfer TOKEN
    function ownerMint(uint256 count) external onlyRole(DESIGNER_ROLE) {
        require(count > 0, "No token to mint");
        address to = msg.sender;
        require(tokenIdCounter.current() + count <= TOTAL_BOX, "Box sold out");
        string memory _tokenURI = _getTokenUri();
        for (uint256 i = 0; i < count; ++i) {
            uint256 id = tokenIdCounter.current();
            tokenIdCounter.increment();
            BoxNFTDetails.BoxNFTDetail memory boxDetail;
            boxDetail.id = id;
            boxDetail.index = i;
            boxDetail.owner_by = to;
            boxDetail.tokenURI = _tokenURI;
            tokenDetails[id] = boxDetail;
            _safeMint(to, id);
            emit TokenCreated(to, id, boxDetail);
        }
        
    }

    function _mintOneOrder(
        uint256 _count,
        address _to
    ) internal returns(BoxNFTDetails.BoxNFTDetail[] memory) {
        BoxNFTDetails.BoxNFTDetail[] memory _returnOrder = new BoxNFTDetails.BoxNFTDetail[](_count);
        string memory _tokenURI = _getTokenUri();
        for (uint256 i = 0; i < _returnOrder.length; ++i) {
            uint256 id = tokenIdCounter.current();
            tokenIdCounter.increment();
            BoxNFTDetails.BoxNFTDetail memory boxDetail;
            boxDetail.id = id;
            boxDetail.index = i;
            boxDetail.owner_by = _to;
            boxDetail.tokenURI = _tokenURI;
            tokenDetails[id] = boxDetail;
            _safeMint(_to, id);
            _returnOrder[i] = BoxNFTDetails.BoxNFTDetail(
                id,
                i,
                false,
                _to,
                tokenURI(id)
            );
            
            emit TokenCreated(_to, id, boxDetail);
        }
        return _returnOrder;
    }

    /** Open multiple Boxes NFT. */
    function openBoxes(uint256[] calldata tokenIds_) external notContract {
        address to = msg.sender;
        require(tokenIds_.length <= MAX_OPEN_BOX_UNIT, "Open over maximun boxs each time.");
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            BoxNFTDetails.BoxNFTDetail memory boxDetail = tokenDetails[tokenIds_[i]];
            require(boxDetail.owner_by == to, "Token not owned");
            require(boxDetail.is_opened == false, "Box already opened");
        }
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            BoxNFTDetails.BoxNFTDetail storage boxDetail = tokenDetails[tokenIds_[i]];
            boxDetail.is_opened = true;
        }
        // Add open Box request
        addBoxOpenRequest(to, tokenIds_.length);

        emit OpenBox(to, tokenIds_);
    }

    /**
     *  @notice Function add Box opening request
     */
    function addBoxOpenRequest(
        address to,
        uint256 count
    ) internal {
        uint256 targetBlock = block.number + 5;
        boxRequests[to].push(
            CreateBoxRequest(
                targetBlock,
                uint16(count)
            )
        );
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

            // Get Box Configurations of current box
            (, uint256 _defaultIndex, ) = IBoxesConfigurations(getBoxConfigurations()).getBoxInfos(address(this));

            // Get data from request
            uint256 targetBlock = request.targetBlock;
            uint256 count = request.count;

            // Check targetBlock reach or not
            require(block.number > targetBlock, "Target block not arrived");

            // Hash current executed block
            uint256 seed = uint256(blockhash(targetBlock));

            // Init with rarity = 0; rarity = 0 means random in all rarities
            uint256 index = 0;

            // Force rarity common if process over 256 blocks.
            if (block.number - 256 > targetBlock) {
                // Force to default rarity
                index = _defaultIndex;
            }

            if (seed == 0) {
                targetBlock = (block.number & maskFirst248Bits) + (targetBlock & maskLast8Bits);
                if (targetBlock >= block.number) {
                    targetBlock -= 256;
                }
                seed = uint256(blockhash(targetBlock));
            }

            // Execute minting action to NFT contract
            executeOneBoxOpening(
                to,
                count,
                index,
                seed
            );

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
        uint256 index,
        uint256 seed
    ) internal {
        uint256 nextSeed = seed;
        CharacterTokenDetails.MintingOrder[] memory _mintingOrders = new CharacterTokenDetails.MintingOrder[](count);
        for (uint256 i = 0; i < count; ++i) {
            uint256 _currId = ICharacterToken(getNftCollection(address(this))).lastId();
            BoxNFTDetails.DropRatesReturn[] memory _dropRateReturns = IBoxesConfigurations(getBoxConfigurations()).getDropRates(address(this));
            // Get DropRates
            uint256[] memory _dropRates = new uint256[](_dropRateReturns.length);
            for (uint256 j=0; j < _dropRateReturns.length; j++) {
                _dropRates[j] = _dropRateReturns[j].dropRate;
            }
            if (index == 0) {
                uint256 _newIndex;
                uint256 tokenSeed = uint256(keccak256(abi.encode(nextSeed, _currId)));
                (nextSeed, _newIndex) = Utils.randomByWeights(tokenSeed, _dropRates);
                index = _newIndex;
            }
            _currId += 1;
            
            _mintingOrders[i] = CharacterTokenDetails.MintingOrder(
                _dropRateReturns[index].attributes.rarity,
                _dropRateReturns[index].attributes.meshIndex,
                _dropRateReturns[index].attributes.meshMaterialIndex
            );
        }
        ICharacterToken(getNftCollection(address(this))).mintOrderForDev(
            _mintingOrders,
            to, 
            "0x01"
        );
    }

    /** User can send tokens directly via d-app. */
    function sendNft(address to, uint256[] calldata tokenIds_) external {
        address from = msg.sender;
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            BoxNFTDetails.BoxNFTDetail memory boxDetail = tokenDetails[tokenIds_[i]];
            require(boxDetail.owner_by == from, "Token not owned");
            require(boxDetail.is_opened == false, "Box already opened");
        }
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            safeTransferFrom(from, to, tokenIds_[i]);
            emit SendNft(from, to, tokenIds_[i]);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // Only transfer via this contract or from Design address
        // require(
        //     from == address(this) || to == address(this) || hasRole(DESIGNER_ROLE, address(from)),
        //     "Support sale/buy on market place only"
        // );
        BoxNFTDetails.BoxNFTDetail storage boxDetail = tokenDetails[tokenId];
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
    )  internal override {
        if (from == address(0)) {
            // Mint.
        } else {
            // Transfer or burn.
            // Swap and pop.
            uint256[] storage ids = tokenIds[from];
            BoxNFTDetails.BoxNFTDetail storage boxDetail = tokenDetails[id];
            uint256 index = boxDetail.index;
            // Assign lastId to index to pop lastId.
            uint256 lastId = ids[ids.length - 1];
            ids[index] = lastId;
            ids.pop();

            // Update index after assign boxDetail to new index.
            BoxNFTDetails.BoxNFTDetail storage boxDetailLastId = tokenDetails[
                lastId
            ];
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
            BoxNFTDetails.BoxNFTDetail storage boxDetail = tokenDetails[id];
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
    function getBoxConfigurations() internal returns (address) {
        return IBoxFactory(owner()).getBoxesConfigurations();
    }

    /**
     *  @notice Function internal for getting current boxCreator address
     *  @dev owner of each box is the box factory
     */
    function getBoxCreator() internal returns (address) {
        return IBoxFactory(owner()).getBoxCreator();
    }

    /**
     *  @notice Function internal for getting NFT collection address 
     *  @dev Owner is Box Factory
     */
    function getNftCollection(address _boxAddress) internal view returns(address) {
        return IBoxFactory(owner()).NftCollection(_boxAddress);
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
