// SPDX-License-Identifier: MIT
// Power by: Katana Inu

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/** KTN smart-contract */

contract KTN is ERC20 {
    constructor() ERC20("Katana Inu Token", "KATA") {
        _mint(msg.sender, 500 * 10 ** 6 * (10 ** 18));
    }
}
