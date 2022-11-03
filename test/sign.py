from web3 import Web3
from pydash import get


_privateKey = "98102796d0dfe116f5af6e9a3c10dc38d316f6c98b3ded8d008b962c7d126460"
_user_address = "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B"
_contract_address = "0x938926Bb46bCb51A0Bf43F73f99500f6b9c217a4"
_data = {
    "discount": 54185000000000000000,
    "cids": [
        "bafkreif7feikgrluozva7y2ipuqyhwbeoefrrwt2dzofipq25xpjyl7o7a",
        "bafkreievoxz3lrxgmig42uywaocjqun64ryqhg67syfgj3f5y623iy2xce",
        "bafkreiclikmcjtjvfr7dgbkbxus3bb4bygexfuhveua73rru43uod5f4dm",
        "bafkreifgahnbch4lphzwzmnjsqc3uhfyy3qpckzmt2n7ijdmz7wa2w6euy"
    ],
    "types": [
        2,
        1,
        1,
        2
    ],
    "rarities": [
        3,
        2,
        3,
        1
    ],
    "deadline": 1667363430
}

def generate_signature():
    _w3 = Web3()
    _encode = _w3.codec.encode_abi(
        [
            'uint256',
            'address',
            'address',
            'uint256',
            'string[]',
            'uint8[]',
            'uint8[]',
            'uint256'
        ],  # [chain_id, user_address, contract_address, discount, cids, types, rarities, deadline]
        [
            97,
            _user_address,
            _contract_address,
            get(_data, "discount"),
            get(_data, "cids"),
            get(_data, "types"),
            get(_data, "rarities"),
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
