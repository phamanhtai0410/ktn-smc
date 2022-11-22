const { ethers } = require('ethers');

function split_sig() {
    var _sig = "0x5378fb195fc690e72cac2dd72d736caf71053fcfd46b2a4ab687b13755f96764654c80b158fc6e0c8cf475a21225c2d554e0fd65bba1eaccfc2499e1b0d1976d1c";
    const { v, r , s } = ethers.utils.splitSignature(_sig);
    console.log(`[${v}, "${r}", "${s}", 1669148853]`);
}

split_sig();
[28, "0x5378fb195fc690e72cac2dd72d736caf71053fcfd46b2a4ab687b13755f96764", "0x654c80b158fc6e0c8cf475a21225c2d554e0fd65bba1eaccfc2499e1b0d1976d", 1669148853]