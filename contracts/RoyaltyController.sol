// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RoyaltyController is AccessControlUpgradeable {

    struct PayoutState {
        uint256 percent;
        uint256 claimedAmount;
    }

    event Withdraw(address receipient, uint256 amount);
    event EmergencyWithdraw(address receipient, uint256 amount);
    event ConfigureTotalRoyaltyRate(address collectionAddress, uint256 totalRoyaltyRate);
    event ConfiureRoyaltiesProportions(address collectionAddress, address[] receivers, uint256[] proportions);
    event ChangeTreasuryAddress(address oldAddress, address newAddress);

    // Access Roles 
    bytes32 constant public EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    bytes32 constant public DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 constant public WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    // The denominator
    uint256 constant public DENOMINATOR = 10000;

    // The list of collections that manages by this contract
    address[] public s_collections;

    // Check flags for the existing of collection in the management collection
    mapping(address => bool) public s_is_collection;

    // The total amount of royalty fee in each collection
    mapping(address => uint256) private s_available;

    // The configuration proportion of each payout wallet address in each collection
    mapping(address => mapping(address => PayoutState)) private s_royalty_configures;

    // The treasury wallet map with collection address
    mapping(address => address) public treasuryAddresses;

    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EMERGENCY_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);
    }

    function changeTreasuryAddress(
        address _newTreasuryAddress,
        address _collectionAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newTreasuryAddress != treasuryAddresses[_collectionAddress], "RoyaltyReceiver: new-address-must-be-different");
        address oldAddress = treasuryAddresses[_collectionAddress];
        treasuryAddresses[_collectionAddress] = _newTreasuryAddress;
        emit ChangeTreasuryAddress(oldAddress, _newTreasuryAddress);
    }

    function withdraw(address tokenAddress, uint256 amount, address collectionAddress) external {
        require(
            IERC20(tokenAddress).balanceOf(treasuryAddresses[collectionAddress]) 
            - s_royalty_configures[collectionAddress][msg.sender].claimedAmount 
            >= amount
            ,
            "Royalty Receiver: Invalid withdraw amount"
        );
        IERC20(tokenAddress).transferFrom(treasuryAddresses[collectionAddress], msg.sender, amount);
        s_royalty_configures[collectionAddress][msg.sender].claimedAmount += amount;
        emit Withdraw(msg.sender, amount);
    }

    function emergencyWithdraw(
        address tokenAddess,
        address collectionAddress,
        uint256 amount
    )
        external onlyRole(EMERGENCY_ROLE)
    {
        require(IERC20(tokenAddess).balanceOf(address(this)) >= amount, "RoyaltyReceiver: Invalid amount");
        IERC20(tokenAddess).transferFrom(treasuryAddresses, msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    function configureRoyaltiesProportions(
        address collectionAddress,
        address[] memory receivers,
        uint256[] memory proportions
    ) 
        external onlyRole(DESIGNER_ROLE)
    {
        uint256 _sum;
        for (uint i=0; i < proportions.length; i++) {
            _sum += proportions[i];
        }
        require(_sum == DENOMINATOR, "RoyaltyReceiver: Invalid proportions for royalties");
        require(receivers.length == proportions.length, "RoyaltyReceiver: Invalid lenth of reveivers and proprtions");
        for (uint i=0; i <= receivers.length; i++) {
            s_royalty_configures[collectionAddress][receivers[i]].percent = proportions[i];
        }
        s_collections.push(collectionAddress);
        s_is_collection[collectionAddress] = true;
        emit ConfiureRoyaltiesProportions(collectionAddress, receivers, proportions);
    }

    function _calculateTotalRoyalty(address triggeredUser) internal view returns(uint256 totalRoyalty) {
        for (uint i=0; i <= s_collections.length; i++) {
            if (s_royalty_configures[s_collections[i]][triggeredUser].percent != 0) {
                totalRoyalty += s_available[s_collections[i]] * s_royalty_configures[s_collections[i]][triggeredUser].percent / DENOMINATOR;
            }
        }
    }
}