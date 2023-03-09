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

var USDT = artifacts.require("USDT");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}

const deployments = {
    factory: false,
    dapp: false,
    config: false,
    reconfig_config_to_factory: false,
    init_config_to_creator: false,
    config_creator_to_factory: false,
    init_config: false,
    set_implement_role_of_nft_for_box: false,
    create_new: false,
    factory_config: true,
    factory_config_drop_rate: true
}

module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    var _devWallet = process.env.iDevWallet;
    var _iUSDT = process.env.iUSDT;

    var _iNftFactory = process.env.KatanaNftFactory;
    var _nftCollection = "0x47bA270646c6D0FDA28f8599D9b95d0be8093C17";
    var _treasuryAddress = "0xF06d7139cD8708de3e9cB2E732A8A158039ebd44";

    /**
     *      1. Deploy Factory
     */
    if (deployments.factory) {
        await deployer.deploy(
            KatanaBoxFactory,
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000",
            _iNftFactory
        );
        var _boxFactory = await KatanaBoxFactory.deployed();
        wf("KatanaBoxFactory", _boxFactory.address);
    } else {
        var _boxFactory = await KatanaBoxFactory.at(process.env.KatanaBoxFactory);
    }

    console.log("Box Factory ", _boxFactory.address);
    
    /**
     *      2. Deploy Box Creator
     */
    if (deployments.dapp) {
        await deployer.deploy(
            BoxNFTCreator,
            _devWallet,
            _iUSDT
        );
        var _boxCreator = await BoxNFTCreator.deployed();
        wf("BoxNFTCreator", _boxCreator.address);
    } else {
        var _boxCreator = await BoxNFTCreator.at(process.env.BoxNFTCreator);
    }
    

    /**
     *      3. Deploy Box Configurations
     */
    if (deployments.config) {
        await deployer.deploy(
            BoxesConfigurations,
            _boxFactory.address,
            _boxCreator.address
        );
        var _boxConfig = await BoxesConfigurations.deployed();
        wf('BoxesConfigurations', _boxConfig.address);
    } else {
        var _boxConfig = await BoxesConfigurations.at(process.env.BoxesConfigurations);
    }
    
    

    /**
     *      4. Initialize BoxConfigurations
     */
    if (deployments.init_config) {
        await _boxConfig.initialize();
    }
    
    /**
     *      5. Re-config box Configutaion for Box Factory
     */
    if (deployments.reconfig_config_to_factory) {
        console.log("Box Config ", _boxConfig.address);
        await _boxFactory.setConfiguration(
            _boxConfig.address
        );
    }
    
    /**
     *      6. Initialize Box Creator
     */
    if (deployments.init_config_to_creator) {
        await _boxCreator.initialize(
            _boxConfig.address
        );    
    }

    /**
     *      7. Re-config boxCreator for Factory
     */
    if (deployments.config_creator_to_factory) {
        await _boxFactory.setDappCreatorAddress(
            _boxCreator.address
        );
    }
        
    /**
     *      7*. Set IMPLEMENTATION ROLE for Box factory in NFT factory
     */
    if (deployments.set_implement_role_of_nft_for_box) {
        var iNftFactory = await KatanaNftFactory.at(process.env.KatanaNftFactory);
        await iNftFactory.grantRole(
            "0x8f257e937a449d287051f1249e0edc3b5d08b547aa4f08807b9ce2a406bcf60f", // IMPLEMENTATION_ROLE
            _boxFactory.address
        );
    }

    /**
     *      8. Create new Box
     */
    if (deployments.create_new) {
        await _boxFactory.createBoxMystery(
            "Mystery Box",
            "MB",
            _iUSDT,
            10000,
            _nftCollection,
            _treasuryAddress, // Katana-treasury-2
            2000
        );    
    }
    
    /**
     *      9. Get address of box
     */
    _boxAddress = await _boxFactory.getBoxAddresAt(0);
    console.log("** Created Box : ", _boxAddress);

    /**
     *      10. Config Box Infos
     */
    if (deployments.factory_config) {
        var _cid = "bafkreigf2an35kovmnt26xs5w7kyb6hggywkincigtkprnm4ofqezozubm";
        var _price = (20 * 10 ** 18).toString();
        await _boxFactory.configOne(
            _boxAddress,
            _cid,
            _price,
            0
        );
    }

    /**
     *      11. Config Droprate
     */
    if (deployments.factory_config_drop_rate) {
        await _boxFactory.configDropRate(
            _boxAddress,
            0,
            0,
            0,
            20
        );
    }
}