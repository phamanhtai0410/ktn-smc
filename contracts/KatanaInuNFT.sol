// SPDX-License-Identifier: MIT
// Power by: Katana Inu

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/** KTN smart-contract */

contract KTN is ERC721, AccessControl {
    
    // Create a new role identifier for the minter role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Define NFT informations
    mapping (uint256 => string) private _tokenURIs;   //create the mapping for TokenID -> URI
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; //Counter to keep track of the number of NFT we minted and make sure we dont try to mint the same twice
    
    constructor() ERC721("Katana Inu Character NFT", "KICN") {
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    function mintNewNFT(string calldata _tokenURI) public onlyAdmin returns (uint256) {  
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenUri(newItemId, _tokenURI);
        _tokenIds.increment();
        return newItemId;
    }

    function uri(uint256 tokenId) public view returns (string memory) { 
        return(_tokenURIs[tokenId]);
    }
    
    function lastId() public view returns (uint256) {
        return _tokenIds.current();
    }
    
    function _setTokenUri(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI; 
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
