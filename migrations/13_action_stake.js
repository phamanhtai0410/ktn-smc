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

    var _characterTokenInstant = await CharacterToken.at(process.env.iCharacterToken);
    var _stakedNFTInstant = await StakeNFT.at(process.env.iStakedNFT);
    

    var _tokenId = 12;
    var _nftCollection = "0x....";
    /**
     *          1. Approve
     */
    await _characterTokenInstant.approve(_stakedNFTInstant.address, _tokenId);

    /**
     *          2. Stake Action
     */
    await StakeNFT.stake(
        _tokenId,
        _nftCollection
    );
}