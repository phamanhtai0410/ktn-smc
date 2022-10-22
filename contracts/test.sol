// SPDX-License-Identifier: MIT
// Power by: Katana Inu

pragma solidity ^0.8.0;


contract Test {
    constructor () {}
    
    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct TestStruct {
        uint8 rarity;
        uint8 nftType;
    }

    mapping(address => mapping(uint8 => mapping(uint8 => uint256[]))) public list;

    mapping(uint8 => TestStruct[]) public test;
    
    function add() external {
        TestStruct memory _test = TestStruct(1, 2);
        test[1].push(_test);
    }
    
    function get(uint8 _a, uint256 _id ) external view returns (uint8) {
        return test[_a][_id].rarity;
    }
    
    function testIfNon() external  {
        if (msg.sender != address(0)) {

        } else {
            TestStruct memory _test = TestStruct(1, 2);
            test[1].push(_test);
        }
    }

    function testMultiMapping(address from, uint8 _nftType, uint8 _rarity, uint256 id) external {
        list[from][_nftType][_rarity].push(id);
    } 

    /**
     *      @notice Function verify signature from daap sent out
     */
    function verifySignature(
        address _signer,
        Proof memory _proof
    ) public pure returns (address) 
    {
        if (_signer == address(0x0)) {
            return address(0x0);
        }
        bytes32 digest = keccak256(abi.encodePacked(
            uint256(97),
            address(0x183Ff214179cd2B1c06A937D663F192340edd159),
            address(0x3E9DFe8715d4034AF6F3A070F0C07Ff2B1bc2fCB),
            uint256(0),
            [
                _convertStringToBytes32("bafkreidfudijruu7e4mjgehgr3szr3rexyqlno3wafg3qqgtmbyj6i7d3y"),
                _convertStringToBytes32("bafkreie2bsk3u4kgxtnlqpf652eil37fkhqs5zx5laozag7jsq76rualf4"),
                _convertStringToBytes32("bafkreicqngcb44wqklgxjozrhw4ge67bjxlrmi7hkyyedkkfrynnil34zu"),
                _convertStringToBytes32("bafkreifiuytiisforeksrt3aw3itv3ajc6wsxm6pvknawoj3nk5t2tm64e")
            ],
            [uint8(2), uint8(2), uint8(2), uint8(2)],
            [uint8(1), uint8(2), uint8(3), uint8(5)],
            uint256(1666341253)
        ));
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return signatory;
    }

    function _convertStringToBytes32(string memory _string) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_string);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_string, 32))
        }
    }

    function _convert2(string memory key) 
        public 
        pure 
        returns (bytes32) 
    {
        return bytes32(abi.encodePacked(key));
    }

    
}