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
import "./interfaces/INFTToken.sol";
import "./interfaces/IBoxNFTCreator.sol";


contract MysteryBoxNFT is
    ERC721Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IERC721Receiver
    {
    using BoxNFTDetails for BoxNFTDetails.BoxNFTDetail;
    using Counters for Counters.Counter;

    event TokenCreated(address to, uint256 tokenId, uint256 details);
    event MintOrderForDev(bytes callbackData, address to, BoxNFTDetails.BoxNFTDetail[] returnMintingOrder);
    event MintOrderFromDaapCreator(string callbackData, address to, BoxNFTDetails.BoxNFTDetail[] returnMintingOrder);
    event OpenBox(address to, uint256[] tokenIds);
    event SendNft(address from, address to, uint256 tokenId);

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public constant COIN_DECIMALS = 10 ** 18;
    uint public constant TOTAL_BOX = 10000;
    uint public constant MAX_OPEN_BOX_UNIT = 5;

    IERC20 public coinToken;
    // DaapCreator contract
    IBoxNFTCreator public boxNFTCreator;

    INFTToken public characterToken;
    Counters.Counter public tokenIdCounter;
    
    // Limit each common user to by.
    uint256 public boxLimit;
    // Box price in KTN
    uint256 public boxPrice;
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

    /**
        * @notice Checks if the msg.sender is a contract or a proxy
    */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyFromDaapCreator() {
        require(msg.sender == address(boxNFTCreator), "Not be called from Box NFT Creator");
        _;
    }

    constructor (address _boxNFTCreator) {
        boxNFTCreator = IBoxNFTCreator(_boxNFTCreator);            
    }

    function initialize(
        IERC20 coinToken_
    ) public initializer {
        __ERC721_init("KATANA MYSTERY BOX NFT", "KTNBOX");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        coinToken = coinToken_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(WHITELIST_ROLE, msg.sender);
        
        // Limit box each user can mint
        boxLimit = 3;
        boxPrice = 100 * COIN_DECIMALS;

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

    /** Enable common user mint box */
    function setBuyable(bool isBuyable) external onlyRole(DESIGNER_ROLE) {
        buyable = isBuyable;
    }

    /** Set whitelist addresses and amount.
    If set after addr whitelistMint tokens, amount will be reset to input amount. */
    function setWhitelist(address addr, uint256 amount) external onlyRole(WHITELIST_ROLE) {
        whiteList[addr] = amount;
        // If owner add addr to whitelist multiple time, whiteListPool will increase multiple time.
        whiteListPool += amount;
    }

    /** Set price for box */
    function setBoxPrice(uint256 boxPrice_)
        external
        onlyRole(DESIGNER_ROLE)
    {
        boxPrice = boxPrice_ * COIN_DECIMALS;
    }

    /** Sets the design for open box. */
    function setCharacterToken(address contractAddress)
        external
        onlyRole(DESIGNER_ROLE)
    {
        characterToken = INFTToken(contractAddress);
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
    ) external onlyFromDaapCreator {
        require(_count > 0, "No token to mint");
        require(tokenIdCounter.current() + _count <= TOTAL_BOX, "Box sold out");
        // Check limit.
        address to = msg.sender;
        require(boughtList[to] + _count <= boxLimit, "User limit buy reached");
        require(buyable == true, "Mint token have not start yet");
        address owner = address(this);
        // Transfer token
        coinToken.transferFrom(to, owner, boxPrice * _count);
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
        address owner = address(this);
        // Transfer token
        coinToken.transferFrom(to, owner, boxPrice * count);
        whiteList[to] -= count;
        for (uint256 i = 0; i < count; ++i) {
            uint256 id = tokenIdCounter.current();
            tokenIdCounter.increment();
            BoxNFTDetails.BoxNFTDetail memory boxDetail;
            boxDetail.id = id;
            boxDetail.index = i;
            boxDetail.price = boxPrice;
            boxDetail.owner_by = to;
            tokenDetails[id] = boxDetail;
            _safeMint(to, id);
            emit TokenCreated(to, id, id);
        }
        whiteListBought += count;
    }

    // Owner mint without transfer TOKEN
    function ownerMint(uint256 count) external onlyRole(DESIGNER_ROLE) {
        require(count > 0, "No token to mint");
        address to = msg.sender;
        require(tokenIdCounter.current() + count <= TOTAL_BOX, "Box sold out");
        for (uint256 i = 0; i < count; ++i) {
            uint256 id = tokenIdCounter.current();
            tokenIdCounter.increment();
            BoxNFTDetails.BoxNFTDetail memory boxDetail;
            boxDetail.id = id;
            boxDetail.index = i;
            boxDetail.price = boxPrice;
            boxDetail.owner_by = to;
            tokenDetails[id] = boxDetail;
            _safeMint(to, id);
            emit TokenCreated(to, id, id);
        }
        
    }

    function _mintOneOrder(
        uint256 _count,
        address _to
    ) internal returns(BoxNFTDetails.BoxNFTDetail[] memory) {
        BoxNFTDetails.BoxNFTDetail[] memory _returnOrder = new BoxNFTDetails.BoxNFTDetail[](_count);
        for (uint256 i = 0; i < _returnOrder.length; ++i) {
            uint256 id = tokenIdCounter.current();
            tokenIdCounter.increment();
            BoxNFTDetails.BoxNFTDetail memory boxDetail;
            boxDetail.id = id;
            boxDetail.index = i;
            boxDetail.price = boxPrice;
            boxDetail.owner_by = _to;
            tokenDetails[id] = boxDetail;
            _safeMint(_to, id);
            _returnOrder[i] = BoxNFTDetails.BoxNFTDetail(
                id,
                i,
                boxPrice,
                false,
                _to
            );
            
            emit TokenCreated(_to, id, id);
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
        characterToken.openBoxes(tokenIds_);
        emit OpenBox(to, tokenIds_);
        
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
