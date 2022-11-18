// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IMysteryBoxNFT.sol";
import "./interfaces/IBoxNFTCreator.sol";
import "./libraries/BoxNFTDetails.sol";


contract BoxNFTCreator is 
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    IBoxNFTCreator
{   
    using SafeERC20 for IERC20;
    using BoxNFTDetails for BoxNFTDetails.BoxNFTDetail;

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
    address public boxConfigurations;

    // NFT collection using
    IMysteryBoxNFT public boxCollection;
    
    // Token using to pay for minting NFT
    IERC20 public payToken;

    // Price of each box.
    uint256 public boxPrice;

    /**
     *      @dev Define events that contract will emit
     */
    event SetNewSigner(address oldSigner, address newSigner);
    event UpdatePrice(uint256 newPrice);
    event MakingMintingAction(uint256 amount, uint256 discount, address to);
    event SetNewPayToken(address oldPayToken, address newPayToken);
    event Withdraw(uint256 amount);

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
    constructor (address _signer, address _boxConfig, IERC20 _payToken) {
        signer = _signer;
        payToken = _payToken;
        boxConfigurations = _boxConfig;
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

        boxPrice = 100 * 10 ** 18;

        _transferOwnership(msg.sender);
    }

    /**
     *      @dev Function allows ADMIN to withdraw token in contract
     */
    function withdraw(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(payToken.balanceOf(address(this)) >= _amount, "Not enough tokens to withdraw");
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
    function setPayToken(address _newPayToken) external onlyRole(UPGRADER_ROLE) {
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
     *  @notice Update price for box
     */
    function updatePrice(uint256 _newPrice) external onlyRole(UPGRADER_ROLE) {
        boxPrice = _newPrice;
        emit UpdatePrice(_newPrice);
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
        uint256 _amount,
        Proof memory _proof
    ) private view returns (bool) 
    {
        if (_signer == address(0x0)) {
            return true;
        }
        bytes32 digest = keccak256(abi.encode(
            getChainID(),
            msg.sender,
            address(this),
            address(boxCollection),
            _discount,
            _amount,
            _proof.deadline
        ));
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory == _signer && _proof.deadline >= block.timestamp;
    }

    /**
     *  @notice Function get boxPirce.
     *
     */
    function getBoxPrice()
        external override view
        returns (uint256)
    {
        return boxPrice;
    }

    /**
     *  @notice Function allow call external from daap to make miting action
     *
     */
    function makeMintingAction(
        uint256 _amount,
        uint256 _discount,
        Proof memory _proof,
        string memory _callbackData
    ) external payable  notContract {
        require(_amount > 0, "Amount of minting NFTs must be greater than 0");
        require(
            verifySignature(
                signer,
                _discount,
                _amount,
                _proof
            ),
            "Invalid Signature"
        );
        uint256 _price = _amount * boxPrice;
        require(payToken.balanceOf(msg.sender) > _price - _discount, "User needs to hold enough token to buy this token");
        payToken.transferFrom(msg.sender, address(this), _price - _discount);
        boxCollection.mintBoxFromDaapCreator(
            _amount,
            msg.sender,
            _callbackData
        );
        emit MakingMintingAction(_amount, _discount, msg.sender);
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