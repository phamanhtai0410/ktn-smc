const { ethers } = require('ethers');

function split_sig() {
    var _sig = "0xf5609b0f7a6f7845f8dd322127ff4e73fd1235f251fcbcfd4235fb89b9808426061677435f71b3743f5422cd4368dc6610fa8fb40c513803b82b4819fdc5a18b1b";
    const { v, r , s } = ethers.utils.splitSignature(_sig);
    console.log(`[${v}, "${r}", "${s}", 1684486341]`);
}

split_sig();
// [28, "0x5378fb195fc690e72cac2dd72d736caf71053fcfd46b2a4ab687b13755f96764", "0x654c80b158fc6e0c8cf475a21225c2d554e0fd65bba1eaccfc2499e1b0d1976d", 1669148853]