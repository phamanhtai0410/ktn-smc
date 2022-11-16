const BoxNFTCreator = artifacts.require("BoxNFTCreator");

const Web3 = require("web3");
const ethers = require('ethers');
const { ecsign } = require('ethereumjs-util');

module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    /**
     *      1. Function vars
     */
    var _index = 0;
    var _amount = 2;
    
    /**
     *      2. Gen signature by owner address
     */
    var _owner = account;                                           // Owner address - Signer
    var _user = "0x16c14c869a3d838CB1eBf589C50D88a1C67F5C9d";       // Address of current user
    var _chainName = "VeChain-testnet";
    var _IDOcontract = "0xe0531b0A54303d80985E10fBDc4778606350F62B";                      // IDO contract
    var _deadline = 1694603717;

    // Read keystore
    var _keystore = JSON.parse(fs.readFileSync('test/tai_keystore'));
    console.log("*** Keystore : ", _keystore);

    // Decrypt keystore to private key
    var _private_key = await thor_devkit.Keystore.decrypt(_keystore, '21021997');
    _private_key = ethers.utils.hexlify(_private_key)
    console.log("*** Private Key : ", _private_key);

    // Encode signature data
    var _encode = Web3.utils.encodePacked(
        1,  // uint(0x1)
        _index,
        _owner,
        _amount
    ); 
    var _msg_full_hash = Web3.utils.keccak256(Web3.utils.encodePacked(
        _chainName,
        _IDOcontract,
        _deadline,
        _encode
    ))
    console.log("*** Encoded msg : ", _msg_full_hash);

    // Signature
    const { v, r, s } = ecsign(
        Buffer.from(_msg_full_hash.slice(2), 'hex'),
        Buffer.from(_private_key.slice(2), 'hex')
    )
    console.log("========================================================================================");
    console.log("====> Signature : ");
    console.log("+ proof.v : ", v);
    console.log("+ proof.r : ", Web3.utils.toHex(r));
    console.log("+ proof.s : ", Web3.utils.toHex(s));
    console.log("+ proof.deadline : ", _deadline);


    /**
     *      3. Call commit to IDO contract
     */

    var _swapIDO_instant = await BoxNFTCreator.at(process.env.SWAP_IDO_ADDRESS);
    await _swapIDO_instant.commit(
        _index,
        _amount,
        [
            v,
            Web3.utils.toHex(r),
            Web3.utils.toHex(s)
        ]
    );

    







    
}
