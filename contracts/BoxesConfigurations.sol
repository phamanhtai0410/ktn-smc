// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract BoxesConfigurations is
    AccessControlUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public NFT_COLLECTION;
    
    uint8 public MAX_BOX_TYPE;

    mapping(address => uint8) public boxType;

    constructor (address _nftColelction) {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        NFT_COLLECTION = _nftColelction;
    }

    function addNewBoxInstant(address _boxInstantContract) external onlyRole(UPGRADER_ROLE) {
        MAX_BOX_TYPE += 1;
        boxType[_boxContract] = MAX_BOX_TYPE;
    }

    function 




}