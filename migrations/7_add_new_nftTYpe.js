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
     *  Add new nft type
     */
    var _maxNftTypeValue = 5;
    var _maxRarityValues = [5, 5, 5, 5];
    await _characterTokenInstant.addNewNftType(
        _maxNftTypeValue,
        _maxRarityValues
    );
}