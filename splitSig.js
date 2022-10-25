const { ethers } = require('ethers');

function split_sig() {
    var _sig = "0x7029c1577e891510dc73cb8e1537e44ac1371ce000ffd1389fab78ebeab37bb56463767d5cd09b87bb1b4a8f1c64b171a6c10147589ba543bca9a07f1f50432e1b";
    const { v, r , s } = ethers.utils.splitSignature(_sig);
    console.log(v, r, s);
}

split_sig();
