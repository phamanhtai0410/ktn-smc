const console = require("console");
const fs = require("fs");
const web3 = require("web3");

var CharacterToken = artifacts.require("CharacterToken");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}


module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    var _characterTokenInstant = await CharacterToken.at(process.env.iCharacterToken);
    
    /**
     *          Mint actions
     */
    var _mintingOrder = [
        [
            1,
            "abc"
        ],
        [
            1,
            "adsad"
        ],
        [
            2,
            "asdasd"
        ]
    ]
    var _to = "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B";
    
    var _orderId =  web3.utils.fromAscii("6340feed08daed595dd1c8c0");
    // "6340feed08daed595dd1c8c0";
    await _characterTokenInstant.mint(
        _mintingOrder,
        _to,
        _orderId
    );
}