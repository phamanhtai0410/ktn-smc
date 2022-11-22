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
var MysteryBoxNFT = artifacts.require('MysteryBoxNFT');

var DaapNFTCreator = artifacts.require("DaapNFTCreator");
var BoxNFTCreator = artifacts.require('BoxNFTCreator');

var KatanaNftFactory = artifacts.require("KatanaNftFactory");
var KatanaBoxFactory = artifacts.require("KatanaBoxFactory");

var NftConfigurations = artifacts.require("NftConfigurations");
var BoxesConfigurations = artifacts.require("BoxesConfigurations");

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

    /**
     *      1. Deploy Factory
     */
    await deployer.deploy(
        KatanaBoxFactory,
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
    );
    var _boxFactory = await KatanaBoxFactory.deployed();
    wf("iBoxfactory", _boxFactory.address);

    /**
     *      2. Deploy Box Creator
     */
    await deployer.deploy(
        BoxNFTCreator,
        _devWallet,
        _iUSDT
    );
    var _boxCreator = await BoxNFTCreator.deployed();
    wf("iBoxCreator", _boxCreator.address);

    /**
     *      3. Deploy Box Configurations
     */
    await deployer.deploy(
        BoxesConfigurations,
        _boxFactory.address,
        _nftCollection,
        _boxCreator.address
    );
    var _boxConfig = await BoxesConfigurations.deployed();
    wf('iBoxConfig', _boxConfig.address);

    /**
     *      4. Initialize BoxConfigurations
     */
    await _boxConfig.initialize();

    /**
     *      5. Re-config box Configutaion for Box Factory
     */
    await _boxFactory.setConfiguration(
        _boxConfig.addresss
    );
    
    /**
     *      6. Initialize Box Creator
     */
    await _boxCreator.initialize(
        _boxConfig.address
    );

    /**
     *      7. Re-config boxCreator for Factory
     */
    await _boxFactory.setDappCreatorAddress(
        _boxCreator.address
    );

    /**
     *      8. Create new Box
     */
    await _boxFactory.createBoxMystery(
        "Mystery Box",
        "MB",
        _iUSDT
    );

    /**
     *      9. Get address of box
     */
    _boxAddress = await _boxFactory.getBoxAddresAt(0);
    console.log("** Created Box : ", _boxAddress);

    /**
     *      10. Config Box Infos
     */
    var _cid = "bafkreigf2an35kovmnt26xs5w7kyb6hggywkincigtkprnm4ofqezozubm";
    var _price = 20 * 10 ** 18;
    await _boxFactory.configOne(
        _boxAddress,
        _cid,
        _prices,
        0
    );

    /**
     *      11. Config Droprate
     */
    await _boxFactory.configDropRate(
        _boxAddress,
        0,
        0,
        0,
        20
    );
}