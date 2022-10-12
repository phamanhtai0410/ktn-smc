const console = require("console");
const fs = require("fs");

var CharacterDesign = artifacts.require("CharacterDesign");
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
    var _to = "0x..";
    var _orderId = "6340feed08daed595dd1c8c0";
    await _characterTokenInstant.mint(
        _mintingOrder,
        _to,
        _orderId
    );
}