// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICharacterToken.sol";

contract DaapNFTCreator is 
    AccessControlUpgradeable,
    PausableUpgradeable
{   
    using SafeERC20 for IERC20;

    /**
     *      @dev Defines using Structs
     */
    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     *      @dev Define variables in contract
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Signer for mint with signature
    address public signer;
    
    // NFT collection using
    ICharacterToken public nftCollection;

    // Token using to pay for minting NFT
    IERC20 public immutable payToken;

    // Price of each rarity type token
    mapping(uint8 => uint256) public nftPrice;

    /**
     *      @dev Define events that contract will emit
     */
    event SetNewSigner(address oldSigner, address newSigner);

    /**
     *      @dev Modifiers using in contract 
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     *      @dev Contructor
     */
    constructor (address _signer, address _nftCollection, IERC20 _payToken ) {
        signer = _signer;
        payToken = _payToken;
        nftCollection = ICharacterToken(_nftCollection);
    }

    /**
     *      @dev Initialize function
     */
    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        uint8[] memory rarityList = nftCollection.getCurrentRarityList();
        for (uint256 i=0; i < rarityList.length; i++) {
            nftPrice[rarityList[i]] = 10**18;
        }
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     *  @notice Set new signer who confirm a call from daap
     */
    function setNewSigner(address _newSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldSigner = signer;
        signer = _newSigner;
        emit SetNewSigner(oldSigner, _newSigner);
    }

    /**
     *  @notice Set price for each rarity type
     */
    function setPriceForRarityType(uint8 _rarity, uint256 _price) external onlyRole(UPGRADER_ROLE) {
        require(nftCollection.isValidRarity(_rarity), "Invalid rarity");
        nftPrice[_rarity] = _price;
    }

    /**
     *  @notice Function return chainID of current implemented chain
     */
    function getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     *      @notice Function verify signature from daap sent out
     */
    function verifySignature(
        address _signer,
        uint256 _discount,
        string[] memory _cids,
        uint8[] memory _rarities,
        Proof memory _proof
    ) private view returns (bool) 
    {
        if (_signer == address(0x0)) {
            return true;
        }
        bytes32 degist = keccak256(abi.encodePacked(
            getChainID(),
            msg.sender,
            address(this),
            _discount,
            _cids,
            _rarities,
            _proof.deadline
        ));
    }


    /**
     *  @notice Function allow call external from daap to make miting action
     *
     */
    function makeMintingAction(
        
    ) external notContract {
        
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