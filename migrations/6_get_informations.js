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
     *          0. Testing
     */
     console.log("1. MAX TOKEN IN A ORDER : ", (await _characterTokenInstant.MAX_TOKENS_IN_ORDER()).toString());
    
    /**
     *      1. Get latest token Id was minted
     */
    console.log("1. Latest TokenID was minted in this contract : ", (await _characterTokenInstant.lastId()).toString());

    /**
     *      2. Get tokenURI of a token
     */
    var _tokenId = 12;
    console.log(
        `2. TokenURI of ${_tokenId} is ${(await _characterTokenInstant.tokenURI(_tokenId)).toString()}`
    );

    /**
     *      3. Gets token ids for the specified owner
     */
    var _to = "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B";
    console.log(`3. List tokenIDs of ${_to} is ${JSON.stringify(await _characterTokenInstant.getTokenIdsByOwner(_to))}`);

    /**
     *      4. Gets token details for the specified owner
     */
    var _to = "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B";
    console.log(`4. List tokenDetails of ${_to} is ${JSON.stringify(await _characterTokenInstant.getTokenDetailsByOwner(_to))}`);
}