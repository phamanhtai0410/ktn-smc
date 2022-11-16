const console = require("console");
const fs = require("fs");
var xlsx = require('node-xlsx');

/**
 *      0.1. Load config from .xlsx file
 */
// var config_obj = xlsx.parse(__dirname + '/configurations.xlsx'); // parses a configurations file
var config_obj = xlsx.parse(fs.readFileSync(__dirname + '/configurations.xlsx')); // parses a buffer
console.log(config_obj)

var MysteryBoxNFT = artifacts.require("MysteryBoxNFT");
var DaapNFTCreator = artifacts.require("DaapNFTCreator");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}


module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    /**
     *      1.1. Deploy MysteryBoxNFT
     */
    var _boxCreator = "0x0000000000000000000000000000000000000000";
    await deployer.deploy(
        MysteryBoxNFT,
        _boxCreator
    );
    var _boxNFTInstant = await MysteryBoxNFT.deployed();
    wf("iMysteryBoxNFT", _boxNFTInstant.address);

    /**
     *      1.2. Initialize MysteryBoxNFT
     */
    await _boxNFTInstant.initialize(
        "0x24ac4ccfb1d4d1e748a01b099e4b1a52662a9233" // ktn token
    );
    
    /**
     *      3.1. Deploy Dapp Creator
     */
    var _signer = "0xF25AbDb08ff0e0e5561198A53F1325dcfBE92428";
    var _nftCollection = _boxNFTInstant.address;
    var _payToken = _KTN_instant.address;
    await deployer.deploy(
        DaapNFTCreator,
        _signer,
        _nftCollection,
        _payToken
    );
    var _boxNFTCreatorInstant = await DaapNFTCreator.deployed();
    wf("iDaapNFTCreator", _boxNFTCreatorInstant.address);

    /**
     *      3.2. Initialize Daap Creator
     */
    await _boxNFTCreatorInstant.initialize();

    /**
     *      4.1. Set Minter for NFT
     */
    var _listMinter = [
        "0xF25AbDb08ff0e0e5561198A53F1325dcfBE92428",
        _boxNFTCreatorInstant.address
    ];
    _listMinter.forEach(async(e) => {
        await _boxNFTInstant.setMinterRole(e);
    });

    /**
     *      4.2. Set daap creator
     */
    await _boxNFTInstant.setDappCreator(_boxNFTCreatorInstant.address);

    /**
     *      4.3. Set UPGRADER for NFT contract in DaapCreator
     */

    await _boxNFTCreatorInstant.grantRole(
        await _boxNFTInstant.UPGRADER_ROLE(),
        account
    );
}


// 0x44F16eB60AB796AE229efC8f295137F9433BcFa4