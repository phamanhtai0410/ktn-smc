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
    
    /**
     *      1. Deploy Factory
     */
    await deployer.deploy(
        KatanaNftFactory,
        "0x0000000000000000000000000000000000000000"
    );
    var _factory = await KatanaNftFactory.deployed();
    wf("iFactory", _factory.address);

    /**
     *      2. Deploy Dapp Creator
     */
    await deployer.deploy(
        DaapNFTCreator,
        "0xF25AbDb08ff0e0e5561198A53F1325dcfBE92428",
        _iUSDT,
        _factory.address
    );
    var _creator = await DaapNFTCreator.deployed();
    wf("iCreator", _creator.address);

    /**
     *      3. Re-config dapp creator for factory
     */
    await _factory.setDappCreatorAddress(
        _creator.address
    );

    /**
     *      4. Create new Collection
     */
    await _factory.createNftCollection(
        "Testing NFT",
        "TN",
        2,
        [
            "test",
            "test2"
        ],
        [
            "1000000000",
            "1000000"
        ]
    );

    /**
     *      4. Get collection address
     */
    var _collectionAddress = await _factory.getAllCollections();
    console.log("4. List collections : ", _collectionAddress[0]);

    /**
     *      5. Deploy BoxConfigurations
     */
    await deployer.deploy(
        BoxesConfigurations,
        _collectionAddress[0]
    );
    var _boxConfig = await BoxesConfigurations.deployed();
    wf("iBoxConfig", _boxConfig.address);

    /**
     *      6. Initialize BoxesConfigurations
     */
    await _boxConfig.initialize();

    /**
     *      7. Initialize DappCreator
     */
    await _creator.initialize();

    /**
     *      8. 
     */
}