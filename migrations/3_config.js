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
     *      Set Design
     */
    var _characterDesignInstant = await CharacterDesign.at(process.env.iCharacterDesign);
    await _characterTokenInstant.setDesign(_characterDesignInstant.address);

    /**
     *      Pause
     */
    await _characterTokenInstant.pause();
    
    /**
     *      Unpause
     */
     await _characterTokenInstant.unpause();
    
    /**
     *      
     */

}