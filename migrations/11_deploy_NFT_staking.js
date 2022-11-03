const { time } = require("console");
const console = require("console");
const fs = require("fs");

const CharacterToken = artifacts.require("CharacterToken");
const KTN = this.artifacts.require("KTN");
const StakeNFT = this.artifacts.require("StakeNFT");


function wf(name, address) {
    fs.appendFileSync('address.txt', name + "=" + address);
    fs.appendFileSync('address.txt', "\r\n");
}

const IS_REDEPLOY = {
    NFT_contract: false,
    KATA_token: true,
    StakedNFT: true
};

module.exports = async function (deployer, network, accounts) {
    let account = deployer.options?.from || accounts[0];
    console.log("*** Deployer = ", account);
    require('dotenv').config();
    const owner = process.env.OwnerAddress;

    /**
     *          1. NFT for Katana Inu
     */
    if (IS_REDEPLOY.NFT_contract) {
        await deployer.deploy(CharacterToken);
        var _CharacterTokenInstant = await CharacterToken.deployed();
        wf("iCharacterToken", _CharacterTokenInstant.address);
    } 
    else {
        var _CharacterTokenInstant = await CharacterToken.at(process.env.iCharacterToken);
    }

    /**
     *          2. KATA token
     */
    if (IS_REDEPLOY.KATA_token) {
        await deployer.deploy(KTN);
        var _KTN_Instant = await KTN.deployed();
        wf("iKTN", _KTN_Instant.address);
    }
    else {
        var _KTN_Instant = await KTN.at(process.env.iKTN);
    }

    /**
     *          3. Deploy Staking contract
     */
    var _nftCollections = [
        "0x..",
        "0x.."
    ];
    var _rewardToken = _KTN_Instant.address;
    var _rewardsPerHour = [
        12,
        12
    ];
    var _startStaking = 1665534513;
    var _endStaking = 1664810913;
    if (IS_REDEPLOY.StakedNFT) {
        await deployer.deploy(
            StakeNFT,
            _nftCollections,
            _rewardToken,
            _rewardsPerHour,
            _startStaking,
            _endStaking
        );
        var _StakedInstant = await N.deployed();
        wf("iStakedNFT", _StakedInstant.address);
    } else {
        var _StakedInstant = await StakeNFT.at(process.env.iStakedNFT);
    }
}