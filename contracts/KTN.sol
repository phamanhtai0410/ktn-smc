// SPDX-License-Identifier: MIT
// Power by: Katana Inu

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/** KTN smart-contract */

contract USDT is ERC20 {
    constructor() ERC20("USD Tether", "USDT") {
        _mint(msg.sender, 500 * 10 ** 6 * (10 ** 18));
    }
}
