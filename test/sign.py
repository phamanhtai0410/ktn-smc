from web3 import Web3
from pydash import get


_privateKey = "98102796d0dfe116f5af6e9a3c10dc38d316f6c98b3ded8d008b962c7d126460"

_user_address = "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B"

_contract_address = "0x938926Bb46bCb51A0Bf43F73f99500f6b9c217a4"

_nft_collection_address = "0xbc78541a00f02ab11b0d8a6f038630840a9f80b3"

_data = {
    "discount": 10 ** 18,
    "rarities": [
        0
    ],
    "meshIndexes": [
        0
    ],
    "meshMaterialIndexes": [
        0
    ],
    "deadline": 1669043433
}

def generate_signature():
    _w3 = Web3()
    _encode = _w3.codec.encode_abi(
        [
            'uint256',
            'address',
            'address',
            'address',
            'uint256',
            'uint256[]',
            'uint256[]',
            'uint256[]',
            'uint256'
        ],  # [chain_id, user_address, contract_address, discount, cids, types, rarities, deadline]
        [
            97,
            _user_address,
            _contract_address,
            _nft_collection_address,
            get(_data, "discount"),
            get(_data, "rarities"),
            get(_data, "meshIndexes"),
            get(_data, "meshMaterialIndexes"),
            get(_data, "deadline")
        ]
    )
    digest = Web3.solidityKeccak(['bytes'], [f'0x{_encode.hex()}'])
    _signed_message = _w3.eth.account.signHash(
        digest,
        private_key=_privateKey
    )

    return _signed_message.signature.hex()

print("* Signature = ", generate_signature())
