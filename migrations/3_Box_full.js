const console = require("console");
const fs = require("fs");
var xlsx = require('node-xlsx');

/**
 *      0.1. Load config from .xlsx file
 */
// var config_obj = xlsx.parse(__dirname + '/configurations.xlsx'); // parses a configurations file
// var config_obj = xlsx.parse(fs.readFileSync(__dirname + '/configurations.xlsx')); // parses a buffer
// console.log(config_obj)

var CharacterToken = artifacts.require("CharacterToken");
var DaapNFTCreator = artifacts.require("DaapNFTCreator");
var KatanaNftFactory = artifacts.require("KatanaNftFactory");
var NftConfigurations = artifacts.require("NftConfigurations");
var BoxesConfigurations = artifacts.require("BoxesConfigurations");
var MysteryBoxNFT = artifacts.require('MysteryBoxNFT');
var BoxNFTCreator = artifacts.require('BoxNFTCreator');
var KTN = artifacts.require("KTN");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}


module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    var _devWallet = process.env.iDevWallet;
    var _iUSDT = process.env.iUSDT;

    var _nftCollection = "0xa3bd2dc7514da9b3244cc10487b6b12365c66e49";
    
    

}