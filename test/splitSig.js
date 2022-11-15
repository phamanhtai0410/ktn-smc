const { ethers } = require('ethers');

function split_sig() {
    var _sig = "0xe9e5d95cc3b5c7292f9dc415885241a01a0fa5116a9d990ca646a6f66329d6326a07e50d5f2476f466562a0c5dc8561c2210f07844663b4d8c2ea04a30c5105a1b";
    const { v, r , s } = ethers.utils.splitSignature(_sig);
    console.log(`[${v}, "${r}", "${s}", 1668510685]`);
}
// (28,0xa74df5bc511f72c3c2667579cd9cae71a0eece7365e9c525893d672992bb30ec,0x2eb755a7dfd05207282138322a3522b1c9ad28f7a42ef82276265d6d30556450,1668503485)
// [28 0x5ad2fd0a69aa5ab6db290edda496853841271db45e79d34e585fce5dc64bfae0, 0x433e35f50dc135fc8207eade1dcdb198cadedb4f91a58dd3d90ae696f16bcf01, 1668503485]
split_sig();
