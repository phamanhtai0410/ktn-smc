// SPDX-License-Identifier: MIT
// Power by: Katana Inu

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./library/MarketItemDetails.sol";

contract KatanaInuMarket is ERC721Upgradeable, AccessControlUpgradeable, UUPSUpgradeable, OwnableUpgradeable, IERC721Receiver {

    using Counters for Counters.Counter;
    using MarketItems for MarketItems.MarketItemDetails;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    // Token use for payment on market
    IERC20 public payToken;

    // Index of nfts
    Counters.Counter public tokenIdCounter;

    // Index of market items
    Counters.Counter public itemIdCounter;

    // Flag check can normal user buy nft on market
    bool public buyable;

    // Mapping from owner address to token ID.
    mapping(address => uint256[]) public itemOwnerIds;

    // Mapping from owner address to token ID.
    mapping(uint8 => mapping(uint8 => uint256)) private itemsTypeBasePrice;

    // Mapping from token ID to token details.
    mapping(uint256 => MarketItems.MarketItemDetails) public itemDetails;

    // Mapping whitelist addresses to buyable amount
    mapping(address => uint256) public whiteList;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function initialize(
        IERC20 payTokenContract
    ) public initializer {
        __ERC721_init("KATANA INU Market", "KATAM");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        payToken = payTokenContract;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(WHITELIST_ROLE, msg.sender);

        // Limit box each user can mint
    }

    /** Marketplace fee */
    function marketFee(uint256 amount) internal pure returns (uint256 fee) {
        // TODO check rate, 450/10000 = 4.5/100
        fee = (amount / 10000) * 45;
    }

    // Withdraw payToken from market
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payToken.transfer(msg.sender, payToken.balanceOf(address(this)));
    }

    /** Enable common user mint box*/
    function setBuyable(bool isBuyable) external onlyRole(DEFAULT_ADMIN_ROLE) {
        buyable = isBuyable;
    }

    /** Set whitelist addresses and amount.
    If set after addr whitelistMint tokens, amount will be reset to input amount. */
    function setWhitelist(address addr, uint256 amount) external onlyRole(WHITELIST_ROLE) {
        whiteList[addr] = amount;
    }

    function getItemIdsByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory ids = itemOwnerIds[owner];
        return ids;
    }

    function getItemByOwner(address owner)
        external
        view
        returns (MarketItems.MarketItemDetails[] memory)
    {
        uint256[] memory ids = itemOwnerIds[owner];
        MarketItems.MarketItemDetails[] memory items = new MarketItems.MarketItemDetails[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            MarketItems.MarketItemDetails memory itemDetail = itemDetails[ids[i]];
            items[i] = itemDetail;
        }
        return items;
    }

    function setItemTypeBasePrice(
        uint8[] memory itemTypes, 
        uint8[] memory rarities, 
        uint256[] memory prices) external onlyRole(DEFAULT_ADMIN_ROLE) {
        //  Check length of params
        require(
            itemTypes.length == rarities.length && itemTypes.length == prices.length,
            "KatanaInuMarket::setItemTypeBasePrice: All params must have the same length!"
        );

        for (uint8 index; index < itemTypes.length; ++index) {
            itemsTypeBasePrice[itemTypes[index]][rarities[index]] = prices[index];
        }
    }

    /** Burns a list of heroes. */
    function burn(uint256[] memory ids) external onlyRole(BURNER_ROLE) {
        for (uint256 i = 0; i < ids.length; ++i) {
            _burn(ids[i]);
        }
    }

    /** Mint one token. */
    function mintOneToken(uint8 itemType, uint8 rarity, uint256 price) public notContract {
        //  0: character, 1: skin, 2: items
        require(itemType < 3, "KatanaInuMarket::mintOneToken: Token type invalid!");
        // Check is exist rarity for the first mint
        require(rarity < 5, "KatanaInuMarket::mintOneToken: Token rarity invalid!");
        // Check base price for the first mint
        require(itemsTypeBasePrice[itemType][rarity] == price, "KatanaInuMarket::mintOneToken: Token price invalid!");

        address to = msg.sender;
        address owner = address(this);

        // Transfer token
        payToken.transferFrom(to, owner, price);

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        MarketItems.MarketItemDetails memory itemDetail;

        itemDetail.tokenId = tokenId;
        itemDetail.price = price;
        itemDetail.isOnMarket = false;
        itemDetail.itemType = itemType;
        itemDetail.rarity = rarity;
        itemDetail.ownerBy = to;

        itemDetails[tokenId] = itemDetail;
        _safeMint(to, tokenId);
        //emit TokenCreated(to, id, id);
    }

    /** Mint list token. */
    function mintListTokens(uint8[] memory itemTypes, uint8[] memory rarities, uint256[] memory prices) external notContract {
        //  Check length of params
        require(
            itemTypes.length == rarities.length && itemTypes.length == prices.length,
            "KatanaInuMarket::mintListTokens: All params must have the same length!"
        );

        // Check buyable.
        require(buyable == true, "KatanaInuMarket::mintListTokens: Mint token have not start yet");

        for (uint8 index = 0; index < itemTypes.length; ++index) {
            mintOneToken(itemTypes[index], rarities[index], prices[index]);
        }
        //emit TokenCreated(to, id, id);
    }

    /** Sale token */
    function sale(uint256 tokenId, uint256 price) external notContract {
        address to = msg.sender;
        require(ownerOf(tokenId) == to, "KatanaInuMarket::sale: Token not owned!");

        MarketItems.MarketItemDetails storage itemDetail = itemDetails[tokenId];

        itemDetail.price = price;
        itemDetail.isOnMarket = true;

        // Market hole token for sale
        transferFrom(to, address(this), tokenId);
        // emit Sale(to, tokenId, boxDetail.price);
    }

    /** Disable for sale on marketplace */
    function deactiveSale(uint256 tokenId) external notContract {
        address to = msg.sender;
        MarketItems.MarketItemDetails storage itemDetail = itemDetails[tokenId];

        require(itemDetail.ownerBy == to, "KatanaInuMarket::deactiveSale: Token not owned!");
        require(itemDetail.isOnMarket, "KatanaInuMarket::deactiveSale: Token already off chain!");

        itemDetail.isOnMarket = false;

        this.approve(to, tokenId);
        transferFrom(address(this), to, tokenId);
        //emit DeactiveSale(to, tokenId, boxDetail.price);
    }

    function buy(uint256 tokenId, uint256 price) external notContract {
        address to = msg.sender;
        //require(tokenIds[to].length + 1 <= boxLimit, "User limit reached");
        MarketItems.MarketItemDetails memory itemDetail = itemDetails[tokenId];
        require(itemDetail.isOnMarket, "KatanaInuMarket::buy: Token not on chain for marketplace!");
        require(price >= itemDetail.price, "KatanaInuMarket::buy: Buy price is too low!");

        require(itemDetail.price <= payToken.balanceOf(to), "KatanaInuMarket::buy: User need hold enough Token to buy this box!");

        // Total fee
        uint256 fee = marketFee(itemDetail.price);

        // Fee for market
        payToken.transferFrom(to, address(this), fee);

        // Fee for the owner
        payToken.transferFrom(to, itemDetail.ownerBy, itemDetail.price - fee);

        // Market hole token for sale
        this.approve(to, tokenId);
        transferFrom(address(this), to, tokenId);
        
        //emit Buy(to, tokenId, itemDetail.price, itemDetail.ownerBy);
    }

    /** User can send tokens directly via d-app. */
    function sendNft(address to, uint256[] calldata tokenIds_) external {
        address from = msg.sender;

        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            MarketItems.MarketItemDetails memory itemDetail = itemDetails[tokenIds_[i]];
            require(itemDetail.ownerBy == from, "KatanaInuMarket::sendNft: Token not owned!");
            require(itemDetail.isOnMarket == false, "KatanaInuMarket::sendNft: Can not send box on the market!");
        }

        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            safeTransferFrom(from, to, tokenIds_[i]);
            //emit SendNft(from, to, tokenIds_[i]);
        }
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