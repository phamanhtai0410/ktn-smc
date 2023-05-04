// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IDappCreator.sol";
import "./ICollection.sol";


interface IGatewayNFT {
  function mintToDappCreator(
    address _dappCreator,
    ICollection _nftCollection,
    uint256[] memory _nftIndexes,
    uint256 _discount,
    bool _isWhitelistMint,
    uint256 _nonce,
    IDappCreator.Proof memory _proof,
    string memory _callbackData,
    address _to
  ) external payable;

  function withdrawETH(
    address _dappCreator,
    address _to,
    uint256 _amount
  ) external payable;
}