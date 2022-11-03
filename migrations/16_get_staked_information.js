const console = require("console");
const fs = require("fs");


const CharacterToken = artifacts.require("CharacterToken");
const KTN = this.artifacts.require("KTN");
const StakeNFT = this.artifacts.require("StakeNFT");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}


module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    var _stakedNFTInstant = await StakeNFT.at(process.env.iStakedNFT);

    /**
     *          1. Get available rewards
     */
    var _staker = "0x....";
    console.log(`1. Get available rewards of ${_staker} is ${(await _stakedNFTInstant.availableRewards(_staker)).toString()}`);

    /**
     *          2. Get list of staked token
     */
    var _user = "0x...";
    var _nftColleciton = "0x....";
    console.log(`2. List staked token of user ${_user} is ${JSON.stringify(await _stakedNFTInstant.getStakedTokens(
        _user,
        _nftColleciton
    ))}`);
    
}