// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract verifySignatureTesting {


    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct MintingOrder {
        uint8 rarity;
        string cid;
        uint8 nftType;
    }

    /**
     *  @notice Function return chainID of current implemented chain
     */
    function getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     *      @notice Function verify signature from daap sent out
     */
    function verifySignature(
        address _signer,
        uint256 _discount,
        string[] memory _cids,
        uint8[] memory _nftTypes,
        uint8[] memory _rarities,
        Proof memory _proof
    ) public view returns (bool) 
    {
        if (_signer == address(0x0)) {
            return true;
        }
        bytes32 digest = keccak256(abi.encode(
            uint256(97),
            msg.sender,
            address(0x938926Bb46bCb51A0Bf43F73f99500f6b9c217a4),
            _discount,
            _cids,
            _nftTypes,
            _rarities,
            _proof.deadline
        ));
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory == _signer;
    }
}