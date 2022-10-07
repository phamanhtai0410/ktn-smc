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
    struct CreateTokenRequest {
        uint256 targetBlock; // Use future block.
        uint16 count; // Amount of tokens to mint.
        uint8 rarity; // 0: random rarity, 1 - 4: specified rarity.
    }

    using Counters for Counters.Counter;
    using CharacterDetails for CharacterDetails.Details;

    event TokenCreateRequested(address to, uint256 block);
    event TokenCreated(address to, uint256 tokenId, uint256 details);
    event ProcessTokenRequests(address to);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant OPEN_NFT_ROLE = keccak256("OPEN_NFT_ROLE");

    uint256 private constant maskLast8Bits = uint256(0xff);
    uint256 private constant maskFirst248Bits = ~uint256(0xff);

    IERC20 public coinToken;
    Counters.Counter public tokenIdCounter;
    IERC721 public marketPlace;
    uint256 public maxFaction;

    struct TokenDetail {
        uint256 id;
        uint256 index;
    }

    // Mapping from owner address to token ID.
    mapping(address => uint256[]) public tokenIds;

    // Mapping from token ID to token details.
    mapping(uint256 => TokenDetail) public tokenDetails;

    // Mapping from owner address to claimable token count.
    mapping(address => mapping(uint256 => uint256)) public claimableTokens;

    // Mapping from owner address to token requests.
    mapping(address => CreateTokenRequest[]) public tokenRequests;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    ICharacterDesign public design;

    function initialize(IERC20 coinToken_) public initializer {
        __ERC721_init("KATANA NFT CHARACTER", "KCHARACTER");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        coinToken = coinToken_;
        maxFaction = 0; // 0 to random faction. 5 for using fix faction.

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(CLAIMER_ROLE, msg.sender);
        _setupRole(OPEN_NFT_ROLE, msg.sender);
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

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        coinToken.transfer(msg.sender, coinToken.balanceOf(address(this)));
    }

    /** Burns a list of Characters. */
    function burn(uint256[] memory ids) override external onlyRole(BURNER_ROLE) {
        for (uint256 i = 0; i < ids.length; ++i) {
            _burn(ids[i]);
        }
    }

    /** Sets the design. */
    function setDesign(address contractAddress)
        external
        onlyRole(DESIGNER_ROLE)
    {
        design = ICharacterDesign(contractAddress);
    }

    function setMarketPlace(address contractAddress) external onlyRole(DESIGNER_ROLE) {
        marketPlace = IERC721(contractAddress);
    }

    function setMaxFaction(uint256 _maxFaction) external onlyRole(DESIGNER_ROLE) {
        maxFaction = _maxFaction;
    }

    /** Gets token details for the specified owner. */
    function getTokenDetailsByOwner(address to)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] storage ids = tokenIds[to];
        uint256[] memory result = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            result[i] = tokenDetails[ids[i]].id;
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

    struct Recipient {
        address to;
        uint256 count;
    }

    /** Mints tokens. */
    function mint(uint256 boxType, uint256 count, uint256 faction) external notContract {
        require(count > 0, "No token to mint");
        require(count <= 20, "Maximum 20 token each time");

        // Check limit.
        address to = msg.sender;
        require(
            tokenIds[to].length + count <= design.getTokenLimit(),
            "User limit reached"
        );

        require(
            boxType > 0 && boxType < 3,
            "Invalid Rarity. 1: Normal box; 2: Golden box"
        );

        require(
            faction >= 0 && faction <= maxFaction,
            "Invalid faction."
        );


        // Transfer coin token.
        coinToken.transferFrom(to, address(this), design.getMintCost(boxType) * count);

        // Create requests
        requestCreateToken(
            to,
            count,
            CharacterDetails.ALL_RARITY
        );
    }

    /** Call from backend when user by character using money in game */
    function safeMint(
        address to,
        uint256 count,
        uint8 rarity
    ) public onlyRole(DESIGNER_ROLE) {
        require(count > 0, "No token to mint");
        require(rarity > 0 && rarity < 4, "Rarity invalid");

        // Check limit.
        require(
            tokenIds[to].length + count <= design.getTokenLimit(),
            "User limit reached"
        );

        // Create requests.
        requestCreateToken(to, count, CharacterDetails.ALL_RARITY);
    }

    /** Call from CharacterBoxBasket token to open character. */
    function useNFTs(
        address to,
        uint256 count,
        uint8 rarity
    )   external override onlyRole(OPEN_NFT_ROLE){
        require(count > 0, "No token to mint");
        require(rarity > 0 && rarity < 4, "Rarity invalid");
        // Check limit.
        // require(
        //     tokenIds[to].length + count <= design.getTokenLimit(),
        //     "User limit reached"
        // );

        // Create requests.
        requestCreateToken(to, count, CharacterDetails.ALL_RARITY);
    }


    /** Requests a create token request. */
    function requestCreateToken(
        address to,
        uint256 count,
        uint8 rarity
    ) internal {
        // Create request.
        uint256 targetBlock = block.number + 5;
        tokenRequests[to].push(
            CreateTokenRequest(
                targetBlock,
                uint16(count),
                uint8(rarity)
            )
        );
        emit TokenCreateRequested(to, targetBlock);
    }

    /** Gets the number of tokens that can be processed at the moment. */
    function getPendingTokens(address to) external view returns (uint256) {
        uint256 result;
        CreateTokenRequest[] storage requests = tokenRequests[to];
        for (uint256 i = 0; i < requests.length; ++i) {
            CreateTokenRequest storage request = requests[i];
            if (block.number > request.targetBlock) {
                result += request.count;
            } else {
                break;
            }
        }
        return result;
    }

    /** Gets the number of tokens that can be processed.  */
    function getProcessableTokens(address to) external view returns (uint256) {
        uint256 result;
        CreateTokenRequest[] storage requests = tokenRequests[to];
        for (uint256 i = 0; i < requests.length; ++i) {
            result += requests[i].count;
        }
        return result;
    }

    /** Processes token requests. */
    function processTokenRequests() external notContract {
        address to = msg.sender;
        uint256 size = tokenIds[to].length;
        uint256 limit = design.getTokenLimit();
        require(size < limit, "User limit reached");

        uint256 available = limit - size;
        // Process maximum 10 requests each time.
        if (available > 50) {
            available = 50;
        }

        CreateTokenRequest[] storage requests = tokenRequests[to];
        for (uint256 i = requests.length; i > 0; --i) {
            CreateTokenRequest storage request = requests[i - 1];
            uint8 rarity = request.rarity;
            uint256 targetBlock = request.targetBlock;
            require(block.number > targetBlock, "Target block not arrived");
            uint256 seed = uint256(blockhash(targetBlock));

            // Force rarity common if process over 256 blocks.
            if (block.number - 256 > targetBlock) {
                rarity = 1;
                // Box basket force to golden
                // if (boxType == CharacterDetails.BOX_TYPE_BASKET) {
                //     rarity = 2;
                // } else {
                //     // Force to common
                //     rarity = 1;
                // }
            }

            if (seed == 0) {
                targetBlock = (block.number & maskFirst248Bits) + (targetBlock & maskLast8Bits);
                if (targetBlock >= block.number) {
                    targetBlock -= 256;
                }
                seed = uint256(blockhash(targetBlock));
            }

            if (available < request.count) {
                request.count -= uint16(available);
                createToken(
                    to,
                    available,
                    rarity,
                    seed
                );
                break;
            }
            available -= request.count;
            createToken(
                to,
                request.count,
                rarity,
                seed
            );
            requests.pop();
            if (available == 0) {
                break;
            }
        }
        emit ProcessTokenRequests(to);
    }

    /** Creates token(s) with a random seed. */
    function createToken(
        address to,
        uint256 count,
        uint8 rarity,
        uint256 seed
    ) internal {
        uint256 nextSeed = seed;
        for (uint256 i = 0; i < count; ++i) {
            uint256 id = tokenIdCounter.current();
            nextSeed = design.createRandomToken(id, rarity);
            tokenIdCounter.increment();
            TokenDetail memory tokenDetail;
            tokenDetail.id = id;
            tokenDetails[id] = tokenDetail;

            _safeMint(to, id);
            emit TokenCreated(to, id, id);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        //require(false, "Temporarily disabled");
        // TODO allow marketplace

        require(
            design._transferable(from, to, tokenId),
            "Only on chain Character allowed to transfer."
        );

        //Only transfer via market contract or from Design address
        // TODO test permission
        require(
            from == address(marketPlace) || to == address(marketPlace) || hasRole(DESIGNER_ROLE, address(from)),
            "Support sale/buy on market place only"
        );

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
            uint256 index = tokenDetails[id].index;
            uint256 lastId = ids[ids.length - 1];
            ids[index] = lastId;
            ids.pop();

            // Update index.
            TokenDetail storage tokenDetail = tokenDetails[lastId];
            tokenDetail.index = index;
        }
        if (to == address(0)) {
            // Burn.
            delete tokenDetails[id];
        } else {
            // Transfer or mint.
            uint256[] storage ids = tokenIds[to];
            uint256 index = ids.length;
            ids.push(id);
            TokenDetail storage tokenDetail = tokenDetails[id];
            tokenDetail.index = index;

            // Check limit if not marketplace
            if (to != address(marketPlace)) {
                require(index + 1 <= design.getTokenLimit(), "User limit reached");
            }
        }
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
