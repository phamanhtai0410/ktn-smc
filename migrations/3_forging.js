const console = require("console");
const fs = require("fs");

var KatanaNftFactory = artifacts.require("KatanaNftFactory");
// var Configurations = artifacts.require("Configurations");
// var DaapNFTCreator = artifacts.require("DaapNFTCreator");
var KtnForging = artifacts.require("KtnForging");
var IERC721 = artifacts.require("IERC721");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}

const deployments = {
    deploy_forging: false,
    init_forging: true,
    create_new: true,
    grant_minter_role: true,
    approve_all_collection_burn: true,
    mint_nft_forging: true
}

module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();
    var _devWallet = process.env.iDevWallet;
    var _iUSDT = process.env.iUSDT;
    
    var _factory = await KatanaNftFactory.at(process.env.KatanaNftFactory);
    
    /**
     *      1. Deploy SMC Forging
     */
    if (deployments.deploy_forging) {
        await deployer.deploy(
            KtnForging,
            _devWallet,
            _iUSDT
        );
        var _forging = await KtnForging.deployed();
        wf("KtnForging", _forging.address);
    } else {
        var _forging = await KtnForging.at(process.env.KtnForging);
    }

    if (deployments.init_forging) {
        await _forging.initialize(process.env.Configurations);
        console.log("Init KtnForging Success")
    }

    /**
     *      2. Grant role MINTER of Collection for Wallet owner.
     */
    if (deployments.grant_minter_role) {
        // 0x7531ff7ef957bfcaf757eeaf9b8fa03914413764 is collection address
        await _factory.setNewMinter("0x7531ff7ef957bfcaf757eeaf9b8fa03914413764", "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B");
        // await _factory.setNewMinter("0x7531ff7ef957bfcaf757eeaf9b8fa03914413764", "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B");
    }

    if (deployments.approve_all_collection_burn) {
        var _collectionBurn = await IERC721.at("0x7531ff7ef957bfcaf757eeaf9b8fa03914413764");
        await _collectionBurn.setApprovalForAll(_forging.address, true);
        console.log("ApproveForAll for contract Forging Burn Success")
    }

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
}
