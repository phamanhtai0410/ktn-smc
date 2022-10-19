// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/ICharacterToken.sol";
import "./libraries/CharacterTokenDetails.sol";


contract StakeNFT is 
    ReentrancyGuard,
    AccessControl,
    IERC721Receiver
{
    using SafeERC20 for IERC20;
    using CharacterTokenDetails for CharacterTokenDetails.TokenDetail;

    // Create a new role identifier for the admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    
    // Modifier check if caller is admin or not
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    // Modifier check if caller is upgrader or not
    modifier onlyUpgrader() {
        require(hasRole(UPGRADER_ROLE, msg.sender), "Caller is not upgrader");
        _;
    }

    // Modifier check 
    modifier onlyWhenInStaking() {
        require(block.timestamp >= startStaking, "Staking is invalid now");
        require(block.timestamp <= endStaking, "Staking's already ended !");
        _;
    }

    modifier onlyWhenEndStaking() {
        require(block.timestamp > endStaking, "Staking hasn't ended yet");
        _;
    }

     // Define events
    event Stake(uint256 tokenId, address to, address nftCollection);
    event Withdraw(uint256 tokenId, address to ,address nftCollection);
    event UnstakeAll(address to, address nftCollection);

    // Staker info
    struct Staker {
        // Amount of tokens staked by the staker
        uint256 amountStaked;

        // Staked token ids
        StakedToken[] stakedTokens;

        // Last time of the rewards were calculated for this user
        uint256 timeOfLastUpdate;

        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
        uint8 rarity;
        uint8 nftType;
    }

    // Mapping of User Address to Staker info
    mapping(address => mapping(address => Staker)) public stakers;

    // Mapping of Token Id to staker. Made for the SC to remember
    // who to send back the ERC721 Token to.
    mapping(address => mapping(uint256 => address)) public stakerAddress;

    // map to keep track of the "index" of tokenId in stakedToken[]
    mapping(address => mapping(uint256 => uint256)) private stakedTokenIdxs;

    // Interfaces for ERC20 and ERC721
    IERC20 public immutable rewardsToken;
    ICharacterToken[] public nftCollections;

    // Rewards per hour per token deposited in wei.
    mapping(address => uint256) public rewardsPerHour;
    
    // Start-time of staking event
    uint256 public startStaking; 

    // End-time of staking event
    uint256 public endStaking;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(
        ICharacterToken[] memory _nftCollections,
        IERC20 _rewardsToken,
        uint256[] memory _rewardsPerHour,
        uint256 _startStaking,
        uint256 _endStaking
    ) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        require(_nftCollections.length == _rewardsPerHour.length, "Invalid config: number of collections and rewards per hour not match");
        nftCollections = _nftCollections;
        rewardsToken = _rewardsToken;
        for (uint256 i; i < _nftCollections.length; i++) {
            rewardsPerHour[address(_nftCollections[i])] = _rewardsPerHour[i];
        }
        startStaking = _startStaking;
        endStaking = _endStaking;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    // Function allow ADMIN to re-config "rewardsPerHour"
    function setRewardsPerHour(uint256 _rewardsPerHour, address _nftCollection) external onlyUpgrader {
        rewardsPerHour[_nftCollection] = _rewardsPerHour;
    }

    // Function allow ADMIN to add new NFT collection and its rewards per hour
    function addNewCollection(uint256 _rewardsPerHour, ICharacterToken _nftCollection) external onlyUpgrader {
        nftCollections.push(_nftCollection);
        rewardsPerHour[address(_nftCollection)] = _rewardsPerHour;
    }

    // Function allow ADMIN to remove new NFT collection and its rewards per hour
    function removeCollection(ICharacterToken _nftCollection) external onlyUpgrader {
        uint256 _index = 0;
        bool isIn = false;
        for (uint256 i=0; i < nftCollections.length; i++) {
            if (nftCollections[i] == _nftCollection) {
                _index = i;
                isIn = true;
                break;
            }
        }    
        require(isIn, "Not found collection in configed list");
        for (uint i=_index; i < nftCollections.length - 1; i++){
            nftCollections[i] = nftCollections[i+1];
        }
        nftCollections.pop();
    }
    
    // Function: check if a nft collection is in List nft collections was configed in this contract or not
    function isInListCollection(ICharacterToken _nftCollection) private view returns (bool) {
        bool _isIn = false;
        for (uint256 i; i< nftCollections.length; i++) {
            if (nftCollections[i] == _nftCollection) {
                _isIn = true;
                break;
            }
        }
        return _isIn;
    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // Increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function stake(uint256 _tokenId, ICharacterToken _nftCollection) external nonReentrant onlyWhenInStaking {
        // If wallet has tokens staked, calculate the rewards before adding the new token
        if (stakers[address(_nftCollection)][msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender, address(_nftCollection));
            stakers[address(_nftCollection)][msg.sender].unclaimedRewards += rewards;
        }

        // Wallet must own the token they are trying to stake
        require(
            _nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this NFT!"
        );

        // Check if the collection in config or not
        require(isInListCollection(_nftCollection), "NFT collection not found in staking config");

        // Transfer the token from the wallet to the Smart contract
        _nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Create StakedToken
        CharacterTokenDetails.TokenDetail memory _tokenDetails = _nftCollection.getTokenDetailsByID(_tokenId);
        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId, _tokenDetails.rarity, _tokenDetails.nftType);

        // Add the token to the stakedTokens array
        stakers[address(_nftCollection)][msg.sender].stakedTokens.push(stakedToken);

        // Increment the amount staked for this wallet
        stakers[address(_nftCollection)][msg.sender].amountStaked++;

        //Add the index of newly stakedToken in stakedTokenIdxs mapping
        stakedTokenIdxs[address(_nftCollection)][_tokenId] = stakers[address(_nftCollection)][msg.sender].stakedTokens.length - 1;

        // Update the mapping of the tokenId to the staker's address
        stakerAddress[address(_nftCollection)][_tokenId] = msg.sender;

        // Update the timeOfLastUpdate for the staker   
        stakers[address(_nftCollection)][msg.sender].timeOfLastUpdate = block.timestamp;

        emit Stake(_tokenId, msg.sender, address(_nftCollection));
    }
    
    // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards
    // decrement the amountStaked of the user and transfer the ERC721 token back to them
    function withdraw(uint256 _tokenId, ICharacterToken _nftCollection) external nonReentrant {
        _unstakeOne(_nftCollection, _tokenId);
        emit Withdraw(_tokenId, msg.sender, address(_nftCollection));
    }

    /**
     *      @notice Function allows user to unstake all staked NFTs of them in one call
     */
    function unstakeAll(ICharacterToken _nftCollection) external nonReentrant {
        StakedToken[] memory _stakedTokens = stakers[address(_nftCollection)][msg.sender].stakedTokens;
        for (uint256 i=0; i < _stakedTokens.length; i++) {
            _unstakeOne(_nftCollection, _stakedTokens[i].tokenId);
        }
        emit UnstakeAll(msg.sender, address(_nftCollection));
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards() external onlyWhenEndStaking {
        uint256 rewards;
        for (uint256 i=0; i < nftCollections.length; i++) {
            address _nftCollection = address(nftCollections[i]);
            rewards += calculateRewards(msg.sender, _nftCollection) + stakers[_nftCollection][msg.sender].unclaimedRewards;
            stakers[_nftCollection][msg.sender].timeOfLastUpdate = block.timestamp;
            stakers[_nftCollection][msg.sender].unclaimedRewards = 0;
        }
        require(rewards > 0, "You have no rewards to claim");
        rewardsToken.safeTransfer(msg.sender, rewards);
    }

    // View available rewards at any point of time 
    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards;
        for (uint256 i=0; i < nftCollections.length; i++) {
            rewards += calculateRewards(_staker, address(nftCollections[i])) +
                stakers[address(nftCollections[i])][_staker].unclaimedRewards;
        }
        return rewards;
    }

    // View available rewards at any point of time of multi users
    function availableRewardsForMultiUsers(address[] memory _stakers) public view returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](_stakers.length);
        for (uint256 i=0; i < _stakers.length; i++) {
            for (uint256 j=0; j < nftCollections.length; j++) {
                rewards[i] += calculateRewards(_stakers[i], address(nftCollections[i])) +
                    stakers[address(nftCollections[i])][_stakers[i]].unclaimedRewards;
            }
        }
        return rewards;
    } 

    // View list staked NFT of each user
    function getStakedTokens(address _user, address _nftCollection) public view returns (StakedToken[] memory) {
        // Check if we know this user
        if (stakers[_nftCollection][_user].amountStaked > 0) {
            // Return all the tokens in the stakedToken Array for this user that are not -1
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_nftCollection][_user].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_nftCollection][_user].stakedTokens.length; j++) {
                if (stakers[_nftCollection][_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_nftCollection][_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }    
        // Otherwise, return empty array
        else {
            return new StakedToken[](0);
        }
    }

    /**
     *  @notice Function internal allows to unstake one token
     */
    function _unstakeOne(ICharacterToken _nftCollection, uint256 _tokenId) internal {
        // Make sure the user has at least one token staked before withdrawing
        require(
            stakers[address(_nftCollection)][msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );

        // Check if the collection in config or not
        require(isInListCollection(_nftCollection), "NFT collection not found in staking config");
        
        // Wallet must own the token they are trying to withdraw
        require(stakerAddress[address(_nftCollection)][_tokenId] == msg.sender, "You don't own this token!");

        // Update the rewards for this user, as the amount of rewards decreases with less tokens.

        uint256 rewards = calculateRewards(msg.sender, address(_nftCollection));
        stakers[address(_nftCollection)][msg.sender].unclaimedRewards += rewards;

        // Get the index of stakedToken from stakedTokenIdxs mapping
        uint256 tokenIdx = stakedTokenIdxs[address(_nftCollection)][_tokenId];
        if (stakers[address(_nftCollection)][msg.sender].stakedTokens[tokenIdx].staker != address(0)) {
            // Set this token's .staker to be address 0 to mark it as no longer staked
            stakers[address(_nftCollection)][msg.sender].stakedTokens[tokenIdx].staker = address(0);

            // Decrement the amount staked for this wallet
            stakers[address(_nftCollection)][msg.sender].amountStaked--;

            // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
            stakerAddress[address(_nftCollection)][_tokenId] = address(0);

            // Transfer the token back to the withdrawer
            _nftCollection.safeTransferFrom(address(this), msg.sender, _tokenId);

            // Update the timeOfLastUpdate for the withdrawer   
            stakers[address(_nftCollection)][msg.sender].timeOfLastUpdate = block.timestamp;

        }
    }

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _staker, address _nftCollection)
        internal
        view
        returns (uint256 _rewards)
    {
        // uint256 _totalRankingPoint = 0;
        // for (uint56 i = 0; i < stakers[_staker].stakedTokens.length; i++) {
        //     _totalRankingPoint += stakers[_staker].stakedTokens[i].ranking_point;
        // }
        return (((
            ((block.timestamp - stakers[_nftCollection][_staker].timeOfLastUpdate) *
                stakers[_nftCollection][_staker].amountStaked)
        ) * rewardsPerHour[_nftCollection]) / 3600);
    }
}
