// SPDX-License-Identifier: MIT
// Power by: Katana Inu

pragma solidity ^0.8.0;


contract Test {
    constructor () {}
    
    struct TestStruct {
        uint8 rarity;
        uint8 nftType;
    }

    mapping(address => mapping(uint8 => mapping(uint8 => uint256[]))) public list;

    mapping(uint8 => TestStruct[]) public test;
    
    function add() external {
        TestStruct memory _test = TestStruct(1, 2);
        test[1].push(_test);
    }
    
    function get(uint8 _a, uint256 _id ) external view returns (uint8) {
        return test[_a][_id].rarity;
    }
    
    function testIfNon() external  {
        if (msg.sender != address(0)) {

        } else {
            TestStruct memory _test = TestStruct(1, 2);
            test[1].push(_test);
        }
    }

    function testMultiMapping(address from, uint8 _nftType, uint8 _rarity, uint256 id) external {
        list[from][_nftType][_rarity].push(id);
    } 
}