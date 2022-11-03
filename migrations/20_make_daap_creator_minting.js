const console = require("console");
const fs = require("fs");
var xlsx = require('node-xlsx');

var CharacterToken = artifacts.require("CharacterToken");
var DaapNFTCreator = artifacts.require("DaapNFTCreator");
var KTN = artifacts.require("KTN");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}


module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    /**
     *          0. Load contract instants
     */
    var _NftInstant = await CharacterToken.at(process.env.iCharacterToken);
    var _DaapCreatorInstant = await DaapNFTCreator.at(process.env.iDaapCreator);
    var _payTokenInstant = await KTN.at(process.env.iKTN);

    /**
     *          1. Make minting action with signature
     */
    var _data = {
        "discount": 54185000000000000000,
        "cids": [
            "bafkreif7feikgrluozva7y2ipuqyhwbeoefrrwt2dzofipq25xpjyl7o7a",
            "bafkreievoxz3lrxgmig42uywaocjqun64ryqhg67syfgj3f5y623iy2xce",
            "bafkreiclikmcjtjvfr7dgbkbxus3bb4bygexfuhveua73rru43uod5f4dm",
            "bafkreifgahnbch4lphzwzmnjsqc3uhfyy3qpckzmt2n7ijdmz7wa2w6euy"
        ],
        "types": [
            2,
            1,
            1,
            2
        ],
        "rarities": [
            3,
            2,
            3,
            1
        ],
        "deadline": 1667363430
    };
    var _signature = {
        "r": "",
        "s": "",
        "v": ""
    }
    await _DaapCreatorInstant.makeMintingAction();

    
}