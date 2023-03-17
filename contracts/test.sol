// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Test {
    struct Pay {
        uint256 percent;
        uint256 claimed;
    }

    mapping(address => mapping(address => Pay)) public s_saves;
    function test(address a, address[] memory b, uint256[] memory  c) external {
       for (uint i = 0 ; i < b.length; i ++) {
           s_saves[a][b[i]].percent = c[i];
       }
    }
}