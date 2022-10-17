const console = require("console");
const fs = require("fs");

var CharacterToken = artifacts.require("CharacterToken");
var DaapNFTCreator = artifacts.require("DaapNFTCreator");
var KTN = artifacts.require("KTN");

function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}


module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("deployer = ", account);
    require('dotenv').config();

    /**
     *      1.1. Deploy Character Token
     */
    var _maxRarityValue = 5;
    var _dappCreator = "0x0000000000000000000000000000000000000000";
    await deployer.deploy(
        CharacterToken,
        _maxRarityValue,
        _dappCreator
    );
    var _characterTokenInstant = await CharacterToken.deployed();
    wf("iCharacterToken", _characterTokenInstant.address);

    /**
     *      1.2. Initialize Character Token
     */
     await _characterTokenInstant.initialize();

    /**
     *      2.1. Deploy payToken
     */
    await deployer.deploy(
        KTN
    );
    var _KTN_instant = await KTN.deployed();
    
    /**
     *      3.1. Deploy Dapp Creator
     */
    var _signer = "0xF25AbDb08ff0e0e5561198A53F1325dcfBE92428";
    var _nftCollection = _characterTokenInstant.address;
    var _payToken = _KTN_instant.address;
    await deployer.deploy(
        DaapNFTCreator,
        _signer,
        _nftCollection,
        _payToken
    );
    var _daapNFTCreatorInstant = await DaapNFTCreator.deployed();
    wf("iDaapNFTCreator", _daapNFTCreatorInstant.address);

    /**
     *      3.2. Initialize Daap Creator
     */
    await _daapNFTCreatorInstant.initialize();

    /**
     *      4.1. Set Minter for NFT
     */
    var _listMinter = [
        "0xF25AbDb08ff0e0e5561198A53F1325dcfBE92428",
        _daapNFTCreatorInstant.address
    ];
    _listMinter.forEach(async(e) => {
        await _characterTokenInstant.setMinterRole(e);
    });

    /**
     *      4.2. Set daap creator
     */
    await _characterTokenInstant.setDappCreator(_daapNFTCreatorInstant.address);

    /**
     *      4.3. Set UPGRADER for NFT contract in DaapCreator
     */

    await _daapNFTCreatorInstant.grantRole(
        await _characterTokenInstant.UPGRADER_ROLE(),
        account
    );
    

}