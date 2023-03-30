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

    var _devWallet = process.env.iDevWallet;
    var _iUSDT = process.env.iUSDT;

    var _iNftFactory = process.env.KatanaNftFactory;
    var _nftCollection = "0x47bA270646c6D0FDA28f8599D9b95d0be8093C17";
    var _treasuryAddress = "0xF06d7139cD8708de3e9cB2E732A8A158039ebd44";

    await deployer.deploy(
        RoyaltyController
    );
    var _royalty = await RoyaltyController.deployed();
    wf("RoyaltyController", _royalty.address);
}