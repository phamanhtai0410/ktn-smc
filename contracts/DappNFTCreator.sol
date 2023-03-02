// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICharacterToken.sol";
import "./interfaces/INftConfigurations.sol";
import "./libraries/CharacterTokenDetails.sol";


contract DaapNFTCreator is 
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{   
    using SafeERC20 for IERC20;
    using CharacterTokenDetails for CharacterTokenDetails.MintingOrder;

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
    address public nftConfigurations;

    // Token using to pay for minting NFT
    IERC20 public payToken;

    /**
     *      @dev Define events that contract will emit
     */
    event SetNewSigner(address oldSigner, address newSigner);
    event UpdatePrice(address nftCollection, uint8 rarity, uint256 newPrice);
    event MakingMintingAction(CharacterTokenDetails.MintingOrder[] mintingInfos, uint256 discount, address to);
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
    constructor (address _signer, IERC20 _payToken) {
        signer = _signer;
        payToken = _payToken;
    }

    /**
     *      @dev Initialize function
     */
    function initialize(address _nftConfigurations) public initializer {
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        nftConfigurations = _nftConfigurations;
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
        address _nftCollection,
        uint256 _discount,
        uint256[] memory _rarities,
        uint256[] memory _meshIndexes,
        uint256[] memory _meshMaterials,
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
            address(_nftCollection),
            _discount,
            _rarities,
            _meshIndexes,
            _meshMaterials,
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
        ICharacterToken _nftCollection,
        CharacterTokenDetails.MintingOrder[] calldata _mintingInfos,
        uint256 _discount,
        Proof memory _proof,
        string memory _callbackData
    ) external payable  notContract {
        require(_mintingInfos.length > 0, "Amount of minting NFTs must be greater than 0");
        uint256[] memory _rarities = new uint256[](_mintingInfos.length);
        uint256[] memory _meshIndexes = new uint256[](_mintingInfos.length);
        uint256[] memory _meshMaterials = new uint256[](_mintingInfos.length);
        for (uint256 i=0; i < _mintingInfos.length; i++) {
            require(
                INftConfigurations(nftConfigurations).checkValidMintingAttributes(
                    address(_nftCollection),
                    _mintingInfos[i]
                ),
                "Invalid minting infos"
            );
            _rarities[i] = _mintingInfos[i].rarity;
            _meshIndexes[i] = _mintingInfos[i].meshIndex;
            _meshMaterials[i] = _mintingInfos[i].meshMaterial;
        }
        require(
            verifySignature(
                signer,
                address(_nftCollection),
                _discount,
                _rarities,
                _meshIndexes,
                _meshMaterials,
                _proof
            ),
            "Invalid Signature"
        );
        uint256 _amount = 0;
        for (uint256 i=0; i < _mintingInfos.length; i++) {
            _amount += INftConfigurations(nftConfigurations).getPrice(
                address(_nftCollection),
                _mintingInfos[i].rarity,
                _mintingInfos[i].meshIndex
            );
        }
        require(payToken.balanceOf(msg.sender) > _amount - _discount, "User needs to hold enough token to buy this token");
        payToken.transferFrom(msg.sender, address(this), _amount - _discount);
        _nftCollection.mintOrderFromDaapCreator(
            _mintingInfos,
            msg.sender,
            _callbackData
        );
        emit MakingMintingAction(_mintingInfos, _discount, msg.sender);
    }

    // function whitelistMint(
    //     ICharacterToken _nftCollection,
    //     CharacterTokenDetails.MintingOrder[] calldata _mintingInfos,
    //     uint256 _discount,
    //     Proof memory _proof,
    //     string memory _callbackData
    // ) external {
    // }

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