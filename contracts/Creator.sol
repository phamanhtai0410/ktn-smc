// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICollection.sol";
import "./interfaces/IConfiguration.sol";

contract DaapNFTCreator is
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    // using CharacterTokenDetails for CharacterTokenDetails.MintingOrder;

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

    // Configurations address
    address public nftConfiguration;

    // Token using to pay for minting NFT
    IERC20 public payToken;

    // Mapping variable to check the existing of one signature (make sure one sig can only be used just one time)
    mapping(bytes => uint8) public isUsedSignatures;

    /**
     *      @dev Define events that contract will emit
     */
    event SetNewSigner(address oldSigner, address newSigner);
    event UpdatePrice(address nftCollection, uint8 rarity, uint256 newPrice);
    event MakingMintingAction(
        uint256[] nftIndexes,
        uint256 discount,
        address to
    );
    event SetNewPayToken(address oldPayToken, address newPayToken);
    event Withdraw(uint256 amount);
    event AddNewCollection(address nftCollection, uint256[] prices);

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
    constructor(address _signer, IERC20 _payToken) {
        signer = _signer;
        payToken = _payToken;
    }

    /**
     *      @dev Initialize function
     */
    function initialize(address _nftConfiguration) public initializer {
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        nftConfiguration = _nftConfiguration;
    }

    /**
     *      @dev Function allows ADMIN to withdraw token in contract
     */
    function withdraw(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            payToken.balanceOf(address(this)) >= _amount,
            "Not enough tokens to withdraw"
        );
        payToken.transfer(msg.sender, _amount);
        emit Withdraw(_amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     *  @notice Function allows UPGRADER to set new PayToken
     */
    function setPayToken(
        address _newPayToken
    ) external onlyRole(UPGRADER_ROLE) {
        address oldPayToken = address(payToken);
        payToken = IERC20(_newPayToken);
        emit SetNewPayToken(oldPayToken, _newPayToken);
    }

    /**
     *  @notice Set new signer who confirm a call from daap
     */
    function setNewSigner(address _newSigner) external onlyRole(UPGRADER_ROLE) {
        address oldSigner = signer;
        signer = _newSigner;
        emit SetNewSigner(oldSigner, _newSigner);
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
     *  @notice Function allow call external from daap to make miting action
     *
     */
    function makeMintingAction(
        ICollection _nftCollection,
        uint256[] memory _nftIndexes,
        uint256 _discount,
        bool _isWhitelistMint,
        uint256 _nonce,
        Proof memory _proof,
        string memory _callbackData
    ) external payable notContract {
        // Check if the list of indexes order has at least one element
        require(
            _nftIndexes.length > 0,
            "Amount of minting NFTs must be greater than 0"
        );

        // Check that any element in the indexes array is a valid type for the triggered collection
        for (uint256 i = 0; i < _nftIndexes.length; i++) {
            require(
                IConfiguration(nftConfiguration).checkValidMintingAttributes(
                    address(_nftCollection),
                    _nftIndexes[i]
                ),
                "Invalid NFT Index"
            );
        }

        // Check if the proof sent to the contract is valid signature
        if (signer != address(0x0)) {
            bytes32 txHash = getTxHash(
                address(_nftCollection),
                _discount,
                _isWhitelistMint,
                _nftIndexes,
                _nonce
            );
            require(
                isUsedSignatures[txHash] == 0,
                "The signature has already been used"
            );
            isUsedSignatures[txHash] == 1;
            require(verifySignature(txHash, _proof), "Invalid Signature");
        }

        uint256 _amount = 0;
        for (uint256 i = 0; i < _nftIndexes.length; i++) {
            _amount += IConfiguration(nftConfiguration).getCollectionPrice(
                address(_nftCollection),
                _nftIndexes[i]
            );
        }

        _discount = signer == address(0x0) ? 0 : _discount;

        require(
            payToken.balanceOf(msg.sender) > _amount - _discount,
            "User needs to hold enough token to buy this token"
        );
        payToken.transferFrom(msg.sender, address(this), _amount - _discount);
        _nftCollection.mint(_nftIndexes, msg.sender, _callbackData);
        emit MakingMintingAction(_nftIndexes, _discount, msg.sender);
    }

    /**
     *  @dev Function allow to hash Transaction's data
     */
    function getTxHash(
        address _nftCollection,
        uint256 _discount,
        bool _isWhitelistMint,
        uint256[] memory _nftIndexes,
        uint256 _nonce
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    getChainID(),
                    msg.sender,
                    address(this),
                    _nftCollection,
                    _discount,
                    _isWhitelistMint,
                    _nftIndexes,
                    nonce,
                    _proof.deadline
                )
            );
    }

    /**
     *      @notice Function verify signature from daap sent out
     */

    function verifySignature(
        bytes32 txHash,
        Proof memory _proof
    ) private view returns (bool) {
        require(signer != address(0x0), "Invalid signer");
        address signatory = ecrecover(txHash, _proof.v, _proof.r, _proof.s);
        return signatory == signer && _proof.deadline >= block.timestamp;
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
