const { time } = require("console");
const console = require("console");
const fs = require("fs");

const KatanaInuNFT = artifacts.require("KatanaInuNFT");
const StakeNFT = this.artifacts.require("StakeNFT");


function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}



module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("*** Deployer = ", account);
    require('dotenv').config();
    const owner = process.env.OwnerAddress;

    /**
     *          1. Deploy NFT for Katana Inu
     */
    await deployer.deploy(
        KatanaInuNFT
    );
    var KatanaInuNFT_Instant = await KatanaInuNFT.deployed();
    wf("KatanaInuNFT", KatanaInuNFT_Instant.address);



}