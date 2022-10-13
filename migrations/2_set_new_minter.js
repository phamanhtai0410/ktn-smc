const console = require("console");
const fs = require("fs");

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
     *          Set new MINTER => dev wallet in Katana Inu Case
     */
    var _minterAddress = "0xF25AbDb08ff0e0e5561198A53F1325dcfBE92428";
    await _characterTokenInstant.setMinterRole(_minterAddress);

    

}