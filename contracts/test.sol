// SPDX-License-Identifier: MIT
// Power by: Katana Inu

pragma solidity ^0.8.0;


contract Test {
    constructor () {}
    
    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct TestStruct {
        uint8 rarity;
        uint8 nftType;
    }

    event UnstakeAll(address to, uint256[] ids);

    uint256[] public stakedToken = [1, 2, 3, 4, 1, 1];

    function unstakeAll() external {
        uint256[] memory _ids = new uint256[](stakedToken.length);
        uint256 _index;
        for (uint256 i=0; i < stakedToken.length; i++) {
            if (stakedToken[i] == uint256(1)) {
                _ids[_index] = stakedToken[i];
                _index = _index + 1;
            }
        }
        emit UnstakeAll(msg.sender, _ids);
    }
}