// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Test {
    constructor () {}

    // using EnumerableSet for EnumerableSet.AddressSet;
    // using EnumerableSet for EnumerableSet.UintSet;
    
    // EnumerableSet.AddressSet private listNftCollections;

    // function getCurrBlockNumber() external view returns(uint256){
    //     return block.number;
    // }

    // function getBlockHash() external view returns (bytes32) {
    //     return blockhash(block.number);
    // }

    // function getBlockHashUint256() external view returns (uint256) {
    //     return uint256(blockhash(block.number));
    // }

    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    function getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function verifySignature(
        address _signer,
        address _nftCollection,
        uint256 _discount,
        uint256[] memory _rarities,
        uint256[] memory _meshIndexes,
        uint256[] memory _meshMaterials,
        Proof memory _proof
    ) public view returns (address) 
    {
        if (_signer == address(0x0)) {
            return address(0x0);
        }
        bytes32 digest = keccak256(abi.encode(
            getChainID(),
            msg.sender,
            address(0x274D9D29408D25d5efAED5EbE92269C4E007B8BC),
            address(_nftCollection),
            _discount,
            _rarities,
            _meshIndexes,
            _meshMaterials,
            _proof.deadline
        ));
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory;
    }



}