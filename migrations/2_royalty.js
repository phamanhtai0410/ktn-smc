const console = require("console");
const fs = require("fs");


var USDT = artifacts.require("USDT");
var RoyaltyController = artifacts.require("RoyaltyController");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}

const deployments = {

}

module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    await deployer.deploy(
        RoyaltyController
    );
    var _royalty = await RoyaltyController.deployed();
    wf("RoyaltyController", _royalty.address);
}