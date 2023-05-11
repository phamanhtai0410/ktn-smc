const console = require("console");
const fs = require("fs");

var KatanaNftFactory = artifacts.require("KatanaNftFactory");
var Configurations = artifacts.require("Configurations");
var DaapNFTCreator = artifacts.require("DaapNFTCreator");
// var USDT = artifacts.require("USDT");

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
    set_limitation: true
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
            _devWallet
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
        console.log("reconfig_config_to_factory success");
    }

    /**
     *      5. Initialize DappCreator
     */
    if (deployments.init_config_to_creator) {
        await _creator.initialize(_nftConfig.address);
        console.log("init_config_to_creator success");
    }

    /**
     *      6. Initialize NftConfigurations
     */
    if (deployments.init_config) {
        // await _nftConfig.initialize();
        console.log("_nftConfig success");
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
            5555,
            "0xde0779f218c65Ad14660b815e3e73F74a5270651", // Katana-Treasury-1
            1000,
            [
                (1 * 10 ** 15).toString(),
                (1 * 10 ** 15).toString(),
                (1 * 10 ** 15).toString()
            ],
            process.env.wETH
        );
    }

    /**
     *      8. Get collection address
     */
    var _collectionAddress = await _factory.getCollectionAddress(0);
    console.log("9. collection[0] : ", _collectionAddress);
    wf("Collection[0]", _collectionAddress);

    /**
     *      9. Set the limittation of collection
     */
    if (deployments.set_limitation) {
        await _factory.configTheLimitation(
            _collectionAddress,
            4555
        )
    }
}

// https://s3.us-east-1.amazonaws.com/static.katanainu.com/metadata/0xee755fa918239826e13bff64ff0184457dc13506/1.json
// https://s3.us-east-1.amazonaws.com/static.katanainu.com/metadata/collection/0xee755fa918239826e13bff64ff0184457dc13506/1.json
