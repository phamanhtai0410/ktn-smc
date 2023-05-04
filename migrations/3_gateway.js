const console = require("console");
const fs = require("fs");

var KatanaNftFactory = artifacts.require("KatanaNftFactory");
var Configurations = artifacts.require("Configurations");
var DaapNFTCreator = artifacts.require("DaapNFTCreator");
var KatanaGatewayNFT = artifacts.require("KatanaGatewayNFT");

// var ERC20 = artifacts.require("USDT");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}

const deployments = {
    gateway: true,
    set_gateway_for_creator: true,
    set_new_gateway_creator: true,
    approve_creator: true,
    set_role_withdraw: true,
    config_creator: true,
    test_mint: true
}

module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();
    
    if (deployments.gateway) {
        await deployer.deploy(
            KatanaGatewayNFT,
            process.env.WETH,
            process.env.ownerGateway
        );
        var _gateway = await KatanaGatewayNFT.deployed();
        wf("KatanaGatewayNFT", _gateway.address);
    } else {
        var _gateway = await KatanaGatewayNFT.at(process.env.KatanaGatewayNFT);
    }
    
    var _creator = await DaapNFTCreator.at(process.env.DaapNFTCreator);

    
    if (deployments.set_gateway_for_creator) {
        await _creator.setNewGateway(_gateway.address);
    }

    var _factory = await KatanaNftFactory.at(process.env.KatanaNftFactory);

    if (deployments.approve_creator) {
        await _gateway.authorizeNFT(process.env.DaapNFTCreator);
        console.log("authorize Creator success");
    }
    if (deployments.set_role_withdraw) {
        await _creator.grantRole("0x0000000000000000000000000000000000000000000000000000000000000000", _gateway.address);
        console.log("grantRole DEFAULT_ADMIN_ROLE for GatewayNFT success");
    }
}