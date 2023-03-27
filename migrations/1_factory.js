const console = require("console");
const fs = require("fs");
var xlsx = require('node-xlsx');

/**
 *      0.1. Load config from .xlsx file
 */
// var config_obj = xlsx.parse(__dirname + '/configurations.xlsx'); // parses a configurations file
// var config_obj = xlsx.parse(fs.readFileSync(__dirname + '/configurations.xlsx')); // parses a buffer
// console.log(config_obj)

var KatanaNftFactory = artifacts.require("KatanaNftFactory");
var Configurations = artifacts.require("Configurations");
var DaapNFTCreator = artifacts.require("DaapNFTCreator");
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
    factory_config: true,
    create_new_box: true,
    factory_config_box: true
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
            _devWallet,
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
            Configurations,
            _factory.address,
            _creator.address
        );
        var _nftConfig = await Configurations.deployed();
        wf("Configurations", _nftConfig.address);
    } else {
        var _nftConfig = await Configurations.at(process.env.Configurations);
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
    // "https://s3.us-east-1.amazonaws.com/static.katanainu.com/metadata",
    // https://s3.us-east-1.amazonaws.com/static.katanainu.com/metadata/collection
    if (deployments.create_new) {
        await _factory.createNftCollection(
            "KatanaInu NFT",
            "TN",
            "https://s3.us-east-1.amazonaws.com/static.katanainu.com/metadata",
            10000,
            "0xde0779f218c65Ad14660b815e3e73F74a5270651", // Katana-Treasury-1
            1000,
            [
                (10 * 10 ** 18).toString(),
                (10 * 10 ** 18).toString(),
                (10 * 10 ** 18).toString()
            ]
        );
    }

    /**
     *      8. Get collection address
     */
    var _collectionAddress = await _factory.getCollectionAddress(0);
    console.log("9. collection[0] : ", _collectionAddress);
    wf("Collection[0]", _collectionAddress);

    /**
     *      9. Config one for colleciton
     */
    // if (deployments.factory_config) {
    //     await _factory.configCollection(
    //         _collectionAddress,
    //         0,
    //         (20 * 10 ** 18).toString()
    //     );
    // }
    
    /**
     *      10. Create new Box
     */
    // if (deployments.create_new_box) {
    //     await _factory.createBox(
    //         "Testing Box",
    //         "TB",
    //         "https://bafkreidfudijruu7e4mjgehgr3szr3rexyqlno3wafg3qqgtmbyj6i7d3y.ipfs.w3s.link/",
    //         100,
    //         "0xF06d7139cD8708de3e9cB2E732A8A158039ebd44", // Katana-Treasury-2
    //         2000,
    //         _collectionAddress
    //     );
    // }

    /**
     *      11. Get box address
     */
    // var _boxAddress = await _factory.getBoxAddress(0);
    // console.log("11. box[0] : ", _boxAddress);
    // wf("Box[0]", _boxAddress);

    /**
     *      12.. Config box
     */
    // if (deployments.factory_config_box) {
    //     await _factory.configBox(
    //         _boxAddress,
    //         (25 * 10 ** 18).toString(),
    //         100
    //     );
    // }
}

// https://s3.us-east-1.amazonaws.com/static.katanainu.com/metadata/0xee755fa918239826e13bff64ff0184457dc13506/1.json
// https://s3.us-east-1.amazonaws.com/static.katanainu.com/metadata/collection/0xee755fa918239826e13bff64ff0184457dc13506/1.json
