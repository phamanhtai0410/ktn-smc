const { ethers } = require('ethers');

function split_sig() {
    var _sig = "0x55e4b31afe8af608e7b7c8d4a23883b4744d912b3f450e599697a98d5af9027f421a3751891733ebb2923f1034a58a3612e289cd6d3e48676d76d81778952d981b";
    const { v, r , s } = ethers.utils.splitSignature(_sig);
    console.log(`[${v}, "${r}", "${s}", 1668679132]`);
}
// (28,0xa74df5bc511f72c3c2667579cd9cae71a0eece7365e9c525893d672992bb30ec,0x2eb755a7dfd05207282138322a3522b1c9ad28f7a42ef82276265d6d30556450,1668503485)
// [28 0x5ad2fd0a69aa5ab6db290edda496853841271db45e79d34e585fce5dc64bfae0, 0x433e35f50dc135fc8207eade1dcdb198cadedb4f91a58dd3d90ae696f16bcf01, 1668503485]
split_sig();
