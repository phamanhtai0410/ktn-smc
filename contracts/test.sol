// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Test {
    constructor () {}

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    
    EnumerableSet.AddressSet private listNftCollections;

    function getCurrBlockNumber() external view returns(uint256){
        return block.number;
    }

    function getBlockHash() external view returns (bytes32) {
        return blockhash(block.number);
    }

    function getBlockHashUint256() external view returns (uint256) {
        return uint256(blockhash(block.number));
    }




}