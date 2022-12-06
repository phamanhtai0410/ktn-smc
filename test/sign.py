from web3 import Web3
from pydash import get


_privateKey = "98102796d0dfe116f5af6e9a3c10dc38d316f6c98b3ded8d008b962c7d126460"

_user_address = "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B"

_contract_address = "0x6328eAE56ef2b7719Ea3187e3b6D66Fc06Da3D02"

_nft_collection_address = "0x1170693b03Ec83f9d295D55da39f6e2A549D5e0E"

_data = {
    "discount": 10 ** 16,
    "rarities": [
        0
    ],
    "meshIndexes": [
        0
    ],
    "meshMaterialIndexes": [
        0
    ],
    "deadline": 1669148853
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
