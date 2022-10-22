const { ethers } = require("ethers");

var _sig = "0xbf2837a742010b30a0638bce6de812cc6d7c1e353417d5a322237bba7363904b10f339e429960fbe4435c5761dfff8767a307cedea15d0f1a4ef0dac2ad5c15b1b";

const { v, r, s } = ethers.utils.splitSignature(_sig);
console.log(v, r, s);