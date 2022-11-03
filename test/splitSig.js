const { ethers } = require('ethers');

function split_sig() {
    var _sig = "0xd7102851827e413b92034eed938fbc8702f50d9a97c702b19b3501568a30058363af44ae5ef3539ddd1a477a6176cff1d2df72950f8a857a1614865c61dacb461b";
    const { v, r , s } = ethers.utils.splitSignature(_sig);
    console.log(v, r, s);
}

split_sig();
