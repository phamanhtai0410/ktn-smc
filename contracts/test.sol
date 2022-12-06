// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Test {
    constructor () {}

    using EnumerableSet for EnumerableSet.UintSet;

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

    // struct Proof {
    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    //     uint256 deadline;
    // }

    // function getChainID() public view returns (uint256) {
    //     uint256 id;
    //     assembly {
    //         id := chainid()
    //     }
    //     return id;
    // }

    // function verifySignature(
    //     address _signer,
    //     address _nftCollection,
    //     uint256 _discount,
    //     uint256[] memory _rarities,
    //     uint256[] memory _meshIndexes,
    //     uint256[] memory _meshMaterials,
    //     Proof memory _proof
    // ) public view returns (address) 
    // {
    //     if (_signer == address(0x0)) {
    //         return address(0x0);
    //     }
    //     bytes32 digest = keccak256(abi.encode(
    //         getChainID(),
    //         msg.sender,
    //         address(0x274D9D29408D25d5efAED5EbE92269C4E007B8BC),
    //         address(_nftCollection),
    //         _discount,
    //         _rarities,
    //         _meshIndexes,
    //         _meshMaterials,
    //         _proof.deadline
    //     ));
    //     address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
    //     return signatory;
    // }

    struct BoxConfigurations {
        string cid;
        uint256 defaultIndex;
        uint256 price;
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) dropRates;
        EnumerableSet.UintSet rarityList;
        EnumerableSet.UintSet meshIndexList;
        EnumerableSet.UintSet meshMaterialList;
    }

    struct Attributes {
        uint256 rarity;
        uint256 meshIndex;
        uint256 meshMaterialIndex;
    }

    struct DropRatesReturn {
        Attributes attributes;
        uint256 dropRate;
    }



    // Box's Informations: mapping box address => BoxConfigurations 
    mapping(address => BoxConfigurations) private boxInfos;

    function setDropRate(
        address _boxAddress,
        uint256 _rarity,
        uint256 _meshIndex,
        uint256 _meshMaterial,
        uint256 _proportion
    ) external {
        boxInfos[_boxAddress].rarityList.add(_rarity);
        boxInfos[_boxAddress].meshIndexList.add(_meshIndex);
        boxInfos[_boxAddress].meshMaterialList.add(_meshMaterial);
        boxInfos[_boxAddress].dropRates[_rarity][_meshIndex][_meshMaterial] = _proportion;
    }

    function getDropRates(address _boxAddress) external view returns(DropRatesReturn[] memory) {
        DropRatesReturn[] memory dropRateReturns = new DropRatesReturn[](boxInfos[_boxAddress].rarityList.length() * boxInfos[_boxAddress].meshIndexList.length() * boxInfos[_boxAddress].meshMaterialList.length());
        uint256 index;
        for (uint256 i=0; i < boxInfos[_boxAddress].rarityList.length(); i++) {
            for (uint256 j=0; j < boxInfos[_boxAddress].meshIndexList.length(); j++) {
                for (uint256 k=0; k < boxInfos[_boxAddress].meshMaterialList.length(); k++) {
                    Attributes memory _attrs;
                    _attrs.rarity = boxInfos[_boxAddress].rarityList.at(i);
                    _attrs.meshIndex = boxInfos[_boxAddress].meshIndexList.at(i);
                    _attrs.meshMaterialIndex = boxInfos[_boxAddress].rarityList.at(i);
                    dropRateReturns[index].attributes = _attrs;
                    dropRateReturns[index].dropRate = boxInfos[
                        _boxAddress
                    ].dropRates[
                        _attrs.rarity
                    ][
                        _attrs.meshIndex
                    ][
                        _attrs.meshMaterialIndex
                    ];
                    index+=1;
                }
            }
        }
        return dropRateReturns;
    }



}