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
    var _KTN_Instant = await KTN.at(process.env.iKTN);

    /**
     *          1. Add new NFT collections
     */
    var _nftCollection = "0x.....";
    var _rewardsPerHours = 121;
    await StakeNFT.addNewCollection(
        _nftCollection,
        _rewardsPerHours
    );

    /**
     *          2. Remove a NFT collection
     */
    var _removingNFTCollection = "0x....";
    await StakeNFT.removeCollection(
        _removingNFTCollection
    );

    /**
     *          3. Re-config Rewards Per Hour of one nft Collection
     */
    var _reconfigNFTcollection = "0x...";
    var _newRewardsPerHours = 122312;
    await StakeNFT.setRewardsPerHour(
        _reconfigNFTcollection,
        _newRewardsPerHours
    );
    
}