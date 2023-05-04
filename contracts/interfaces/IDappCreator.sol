// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ICollection.sol";


interface IDappCreator {
    /**
     *      @dev Defines using Structs
     */
    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
    
    function mintingFromGateway(
        ICollection _nftCollection,
        uint256[] memory _nftIndexes,
        uint256 _discount,
        bool _isWhitelistMint,
        uint256 _nonce,
        Proof memory _proof,
        string memory _callbackData,
        address _to
    ) external payable;

    /**
     *  @notice Function allow send Token from Treasury to Gateway
     */
    function withdraw(
        uint256 _amount,
        address _payToken
    ) external;


}