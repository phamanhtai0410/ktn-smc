const BoxNFTCreator = artifacts.require("BoxNFTCreator");

const Web3 = require("web3");
const ethers = require('ethers');


module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

}
