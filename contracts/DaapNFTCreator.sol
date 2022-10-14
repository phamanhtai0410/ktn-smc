// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICharacterToken.sol";
import "./CharacterToken.sol";

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

    using MintingInfo for CharacterToken.MintingOrder;

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

    // Price of each nft type with each rarity token
    mapping(uint8 => mapping(uint8 => uint256)) public nftPrice;

    /**
     *      @dev Define events that contract will emit
     */
    event SetNewSigner(address oldSigner, address newSigner);
    event UpdatePrice(uint8 nftType, uint8 rarity, uint256 newPrice);
    event MakingMintingAction(MintingInfo[] mintingInfos, uint256 discount, address to);
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
    constructor (address _signer, address _nftCollection, IERC20 _payToken) {
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

        for (uint8 i=1; i < nftCollection.getMaxNftType() + 1; i++) {
            for (uint8 j=1; j < nftCollection.getMaxRarityValue(i) + 1; j++) {
                nftPrice[i][j] = 100 * 10 ** 18;
            }
            
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
    function upgradeNewNftType(uint8 _newMaxNftType, uint8[] memory _maxRarityList) external onlyRole(UPGRADER_ROLE) {
        for (uint8 i=0; i < _maxRarityList.length; i++) {
            for (uint8 j=1; j <= _maxRarityList[i]; j++) {
                nftPrice[nftCollection.getMaxNftType() + i +  1][j] = 100 * 10 ** 18;
            }
        }
    }

    /**
     *  @notice Upgradde max rarity of one existing nft type
     */
    function upgradeExisitingNftType(uint8 _exisitingNftType, uint8 _upgradeMaxRarity) external onlyRole(UPGRADER_ROLE) {
        for (uint8 i = nftCollection.getMaxRarityValue(_exisitingNftType) + 1; i <= _upgradeMaxRarity; i++) {
            nftPrice[_exisitingNftType][i] = 100 * 10 ** 18;
        }
    }

    /**
     *  @notice Update price for a nft type in one rarity level
     */
    function updatePrice(uint8 _nftType, uint8 _rarity, uint256 _newPrice) external onlyRole(UPGRADER_ROLE) {
        nftPrice[_nftType][_rarity] = _newPrice;
        emit UpdatePrice(_nftType, _rarity, _newPrice);
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
        bytes32[] memory _cids,
        uint8[] memory _nftTypes,
        uint8[] memory _rarities,
        Proof memory _proof
    ) private view returns (bool) 
    {
        if (_signer == address(0x0)) {
            return true;
        }
        bytes32 digest = keccak256(abi.encodePacked(
            getChainID(),
            msg.sender,
            address(this),
            _discount,
            _cids,
            _nftTypes,
            _rarities,
            _proof.deadline
        ));
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory == _signer && _proof.deadline >= block.timestamp;
    }


    /**
     *  @notice Function allow call external from daap to make miting action
     *
     */
    function makeMintingAction(
        MintingInfo[] calldata _mintingInfos,
        uint256 _discount,
        Proof memory _proof
    ) external view notContract {
        require(_mintingInfos.length > 0, "Amount of minting NFTs must be greater than 0");
        bytes32[] memory _cids = new bytes32[](_mintingInfos.length);
        uint8[] memory _nftTypes = new uint8[](_mintingInfos.length);
        uint8[] memory _rarities = new uint8[](_mintingInfos.length);
        for (uint256 i=0; i < _mintingInfos.length; i++) {
            _cids[i] = _mintingInfos[i].cid;
            require(
                _mintingInfos[i].nftType <= nftCollection.getMaxNftType(),
                "Invalid nft type"
            );
            _nftTypes[i] = _mintingInfos[i].nftType;
            require(
                _mintingInfos[i].rarity <= nftCollection.getMaxRarityValue(_mintingInfos[i].nftType),
                "Invalid nft type"
            );
            _rarities[i] = _mintingInfos[i].rarity;
        }
        require(
            verifySignature(
                signer,
                _discount,
                _cids,
                _nftTypes,
                _rarities,
                _proof
            ),
            "Invalid Signature"
        );
        uint256 _amount = 0;
        for (uint256 i=0; i < _mintingInfos.length; i++) {
            _amount += nftPrice[_mintingInfos[i].nftType][_mintingInfos[i].rarity];
        }
        bytes memory _callbackData = bytes("daap-creator");
        payToken.transferFrom(msg.sender, address(this), _amount - _discount);
        nftCollection.mint(
            _mintingInfos,
            msg.sender,
            _callbackData
        );
        emit MakingMintingAction(_mintingInfos, _discount, msg.sender);
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