'use strict';

const Web3 = require('web3');
const { ecsign } = require('ethereumjs-util');


// var _sig = "0xe5669c8c0cd1e958c920a31b760a58abec986fd2c4244c0690a3afa944d49a40333a00a5080f01a939282ca038b1e41149def82f433f7e1a7720c795a7262de11b";

// const { v, r, s } = ethers.utils.splitSignature(_sig);
// console.log(v, r, s);





async function test() {

    var data = {
        "discount": 0,
        "cids": [
            "bafkreifiuytiisforeksrt3aw3itv3ajc6wsxm6pvknawoj3nk5t2tm64e"
        ],
        "types": [
            2
        ],
        "rarities": [
            5
        ],
        "deadline": 1666422347
    };
    
    var _privateKey = "98102796d0dfe116f5af6e9a3c10dc38d316f6c98b3ded8d008b962c7d126460";

    var _user = "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B";
    var _contract_address = "0xf11B8754eE6eC19c0c5e4bC682cF5095a5A9C350";

    // Encode signature dat
    
    var _msg_full_hash = Web3.utils.keccak256(Web3.utils(   
        97,
        _user,
        _contract_address,
        ["bafkreifiuytiisforeksrt3aw3itv3ajc6wsxm6pvknawoj3nk5t2tm64e"],
        [2],
        [5],
        1666422347
    ))

    console.log("*** Encoded msg : ", _msg_full_hash);
    // Signature
    const { v, r, s } = ecsign(
        Buffer.from(_msg_full_hash.slice(2), 'hex'),
        Buffer.from(_privateKey.slice(2), 'hex')
    )
    console.log("======================");
    console.log("*** Signature : ");
    console.log("+ proof.v : ", v);
    console.log("+ proof.r : ", Web3.utils.toHex(r));
    console.log("+ proof.s : ", Web3.utils.toHex(s));
    console.log("+ proof.deadline : ", _deadline);
}
test();
