// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/IGatewayNFT.sol";
import "./interfaces/IDappCreator.sol";


contract KatanaGatewayNFT is Ownable {
    IWETH internal WETH;

    /**
     * @dev Sets the WETH address and owner this contract. Infinite approves DappCreator.
     * @param _weth Address of the Wrapped Ether contract
     * @param _owner Address of the owner of this contract
     **/
    constructor(address _weth, address _owner) {
        WETH = IWETH(_weth);
        transferOwnership(_owner);
    }

    /**
     * @dev Authorize for DappCreator contract to receive or withdraw Native Token(ETH).
     * @param _contractAuthorize Contract Address of DappCreator
     **/
    function authorizeNFT(address _contractAuthorize) external onlyOwner {
        WETH.approve(_contractAuthorize, type(uint256).max);
    }

    /**
     * @dev Update WETH address this contract.
     * @param _weth Address of the Wrapped Ether contract
     **/
    function updateWETH(address _weth) external onlyOwner {
        WETH = IWETH(_weth);
    }

    /**
     * @dev Allows users mint NFTs to pay with Native Token & Convert WETH to DappCreator.
     */
    function mintToDappCreator(
        address _dappCreator,
        ICollection _nftCollection,
        uint256[] memory _nftIndexes,
        uint256 _discount,
        bool _isWhitelistMint,
        uint256 _nonce,
        IDappCreator.Proof memory _proof,
        string memory _callbackData
    ) external payable {
        WETH.deposit{value: msg.value}();
        IDappCreator(_dappCreator).mintingFromGateway(
            _nftCollection,
            _nftIndexes,
            _discount,
            _isWhitelistMint,
            _nonce,
            _proof,
            _callbackData,
            msg.sender
        );
    }

    /**
     * @dev Convert WETH to ETH when call function withdraw token from DappCreator contract
     * direct transfers to the wallet address.
     * @param _dappCreator DappCreator contract address
     * @param _to recipient of the transfer
     * @param _amount amount to send
     */
    function withdrawETH(
        address _dappCreator,
        address _to,
        uint256 _amount
    ) external payable onlyOwner {
        IDappCreator(_dappCreator).withdraw(
            _amount,
            address(WETH)
        );
        WETH.withdraw(_amount);
        _safeTransferETH(_to, _amount);
    }

    /**
     * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param token token to transfer
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /**
     * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computated contract address before deployment.
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransfer(
        address to,
        uint256 amount
    ) external onlyOwner {
        _safeTransferETH(to, amount);
    }

    /**
     * @dev   transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev Get WETH address used by WETHGateway
     */
    function getWETHAddress() external view returns (address) {
        return address(WETH);
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }
}
