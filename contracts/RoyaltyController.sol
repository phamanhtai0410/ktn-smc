// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RoyaltyController is AccessControlUpgradeable {
    struct PayoutState {
        uint256 percent;
        uint256 claimedAmount;
    }

    struct TreasuryInfo {
        address treasuryAddress;
        uint256 totalAlreadyWithdraw;
    }

    event Withdraw(address receipient, uint256 amount);
    event EmergencyWithdraw(address receipient, uint256 amount);
    event ConfigureTotalRoyaltyRate(
        address collectionAddress,
        uint256 totalRoyaltyRate
    );
    event ConfigureRoyaltiesProportions(
        address collectionAddress,
        address[] receivers,
        uint256[] proportions
    );
    event ChangeTreasuryAddress(address oldAddress, address newAddress);

    // Access Roles
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    // The denominator
    uint256 public constant DENOMINATOR = 10000;

    // The list of collections that manages by this contract
    address[] public s_collections;

    // Check flags for the existing of collection in the management collection
    mapping(address => bool) public s_is_collection;

    // The total amount of royalty fee in each collection
    // mapping(address => uint256) private s_available;

    // The configuration proportion of each payout wallet address in each collection
    mapping(address => mapping(address => PayoutState))
        private s_royalty_configures;

    // The treasury wallet map with collection address
    mapping(address => TreasuryInfo) public s_treasury_info;

    // mapping(address => address) public treasuryAddresses;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EMERGENCY_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);
    }

    function changeTreasuryAddress(
        address _newTreasuryAddress,
        address _collectionAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            s_is_collection[_collectionAddress],
            "RoyaltyReceiver: Invalid collection address"
        );
        require(
            _newTreasuryAddress !=
                s_treasury_info[_collectionAddress].treasuryAddress,
            "RoyaltyReceiver: new-address-must-be-different"
        );
        address oldAddress = s_treasury_info[_collectionAddress]
            .treasuryAddress;
        s_treasury_info[_collectionAddress]
            .treasuryAddress = _newTreasuryAddress;
        emit ChangeTreasuryAddress(oldAddress, _newTreasuryAddress);
    }

    function withdraw(
        address tokenAddress,
        uint256 amount,
        address collectionAddress
    ) external {
        require(amount > 0, "Royalty Receiver: Can not withdraw zero");
        require(
            s_is_collection[collectionAddress],
            "RoyaltyReceiver: Invalid collection address"
        );
        require(
            (_calculateCurrentTotalRoyalty(collectionAddress, tokenAddress) *
                s_royalty_configures[collectionAddress][msg.sender].percent) /
                DENOMINATOR -
                s_royalty_configures[collectionAddress][msg.sender]
                    .claimedAmount >=
                amount,
            "Royalty Receiver: Invalid withdraw amount"
        );
        s_royalty_configures[collectionAddress][msg.sender]
            .claimedAmount += amount;
        s_treasury_info[collectionAddress].totalAlreadyWithdraw += amount;
        require(
            IERC20(tokenAddress).transferFrom(
                s_treasury_info[collectionAddress].treasuryAddress,
                msg.sender,
                amount
            ),
            "Royalty Receiver: Transfer failed"
        );
        emit Withdraw(msg.sender, amount);
    }

    function emergencyWithdraw(
        address tokenAddess,
        address collectionAddress,
        uint256 amount
    ) external onlyRole(EMERGENCY_ROLE) {
        require(
            s_is_collection[collectionAddress],
            "RoyaltyReceiver: Invalid collection address"
        );
        require(
            IERC20(tokenAddess).balanceOf(
                s_treasury_info[collectionAddress].treasuryAddress
            ) >= amount,
            "RoyaltyReceiver: Invalid amount"
        );
        IERC20(tokenAddess).transferFrom(
            s_treasury_info[collectionAddress].treasuryAddress,
            msg.sender,
            amount
        );
        emit EmergencyWithdraw(msg.sender, amount);
    }

    function configureRoyaltiesProportions(
        address collectionAddress,
        address[] memory receivers,
        uint256[] memory proportions
    ) external onlyRole(DESIGNER_ROLE) {
        require(
            !s_is_collection[collectionAddress],
            "RoyaltyReceiver: this collection has been configured"
        );
        uint256 _sum;
        for (uint i = 0; i < proportions.length; i++) {
            _sum += proportions[i];
        }
        require(
            _sum == DENOMINATOR,
            "RoyaltyReceiver: Invalid proportions for royalties"
        );
        require(
            receivers.length == proportions.length,
            "RoyaltyReceiver: Invalid lenth of reveivers and proportions"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            s_royalty_configures[collectionAddress][receivers[i]] = PayoutState(
                proportions[i],
                0
            );
        }
        s_collections.push(collectionAddress);
        s_is_collection[collectionAddress] = true;

        emit ConfigureRoyaltiesProportions(
            collectionAddress,
            receivers,
            proportions
        );
    }

    function _calculateCurrentTotalRoyalty(
        address _collectionAddress,
        address _tokenAddress
    ) internal view returns (uint256) {
        return
            IERC20(_tokenAddress).balanceOf(
                s_treasury_info[_collectionAddress].treasuryAddress
            ) + s_treasury_info[_collectionAddress].totalAlreadyWithdraw;
    }
}
