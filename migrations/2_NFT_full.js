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
var USDT = artifacts.require("USDT");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}

const deployments = {
    factory: true,
    dapp: true,
    config: true,
    reconfig_config_to_factory: true,
    init_config_to_creator: true,
    init_config: true,
    create_new: true,
    factory_config: true
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
    if (deployments.factory) {
        await deployer.deploy(
            KatanaNftFactory,
            "0x0000000000000000000000000000000000000000",
        );
        var _factory = await KatanaNftFactory.deployed();
        wf("KatanaNftFactory", _factory.address);
    } else {
        var _factory = await KatanaNftFactory.at(process.env.KatanaNftFactory);
    }
    

    /**
     *      2. Deploy Dapp Creator
     */
    if (deployments.dapp) {
        await deployer.deploy(
            DaapNFTCreator,
            "0xF25AbDb08ff0e0e5561198A53F1325dcfBE92428",
            _iUSDT
        );
        var _creator = await DaapNFTCreator.deployed();
        wf("DaapNFTCreator", _creator.address);
    } else {
        var _creator = await DaapNFTCreator.at(process.env.DaapNFTCreator);
    }

    /**
     *      3. Deploy NftConfigurations
     */
    if (deployments.config) {
        await deployer.deploy(
            NftConfigurations,
            _factory.address,
            _creator.address
        );
        var _nftConfig = await NftConfigurations.deployed();
        wf("NftConfigurations", _nftConfig.address);
    } else {
        var _nftConfig = await NftConfigurations.at(process.env.NftConfigurations);
    }
    
    /**
     *      4. Re-config NftConfigurations to NftFactory
     */
    if (deployments.reconfig_config_to_factory) {
        await _factory.setConfiguration(
            _nftConfig.address
        );
    }

    /**
     *      5. Initialize DappCreator
     */
    if (deployments.init_config_to_creator) {
        await _creator.initialize(_nftConfig.address);
    }

    /**
     *      6. Initialize NftConfigurations
     */
    if (deployments.init_config) {
        await _nftConfig.initialize();
    }

    /**
     *      7. Create new Collection
     */
    if (deployments.create_new) {
        await _factory.createNftCollection(
            "Testing NFT",
            "TN",
            10000,
            "0xde0779f218c65Ad14660b815e3e73F74a5270651", // Katana-Treasury-1
            1000
        );
    }

    /**
     *      8. Get collection address
     */
    var _collectionAddress = await _factory.getCollectionAddress(0);
    console.log("9. collection[0] : ", _collectionAddress);

    /**
     *      9. Config one for colleciton
     */
    if (deployments.factory_config) {
        await _factory.configOne(
            _collectionAddress,
            0,
            0,
            (20 * 10 ** 18).toString(),
            0,
            "test"
        );
    }
    
}