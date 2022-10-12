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

    /**
     *      Deploy Character Design 
     */
    await deployer.deploy(
        CharacterDesign
    );
    var _characterDesignInstant = await CharacterDesign.deployed();
    wf("iCharacterDesign", _characterDesignInstant.address);

    /**
     *      Initialize Character Design
     */
    await _characterDesignInstant.initialize();

    /**
     *      Deploy Character Token
     */
     await deployer.deploy(
        CharacterToken
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