// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Test is ERC721 {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    string public constant s_uri =
        "https://static.katanainu.com/metadata/0x75a068654a93c33950ebb13c71041b8ed0422b46/5.json";

    function mint(uint256 _tokenId) external {
        _mint(msg.sender, _tokenId);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return s_uri;
    }
}
