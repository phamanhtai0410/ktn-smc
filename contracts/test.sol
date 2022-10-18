// SPDX-License-Identifier: MIT
// Power by: Katana Inu

pragma solidity ^0.8.0;


contract Test {
    constructor () {}
    mapping(uint8 => uint256[]) public test;
    function add(uint256 a) external {
        uint256[] storage _list = test[1];
        _list.push(a);
    }
}