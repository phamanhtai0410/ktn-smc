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

    /**
     *      Deploy Character Token
     */
    var _rarityList = [0, 1, 2, 3, 4, 5];
    await deployer.deploy(
        CharacterToken,
        _rarityList
    );
    var _characterTokenInstant = await CharacterToken.deployed();
    wf("iCharacterToken", _characterTokenInstant.address);

    /**
     *      Initialize Character Design
     */
     await _characterTokenInstant.initialize();

     /**
      *     
      */

}