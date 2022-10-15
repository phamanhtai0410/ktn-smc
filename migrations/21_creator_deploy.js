const console = require("console");
const fs = require("fs");

var DaapNFTCreator = artifacts.require("DaapNFTCreator");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}


module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    /**
     *  @notice 
     */

}