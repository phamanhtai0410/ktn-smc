import web3
from web3 import Web3
from pydash import get

_w3 = Web3()
_privateKey = "98102796d0dfe116f5af6e9a3c10dc38d316f6c98b3ded8d008b962c7d126460"
_api_sig = "0xb90af5eb90aca374520df542c4f89564e830c7a230e86bf40c0f80fc85d37ea01dee010b43b8845be182640431a6d37e455302bafaad008a25440197c403171b1b"
data = {
    "discount": 0,
    "cids": [
        "bafkreifiuytiisforeksrt3aw3itv3ajc6wsxm6pvknawoj3nk5t2tm64e"
    ],
    "types": [
        2
    ],
    "rarities": [
        5
    ],
    "deadline": 1666527542
}
_encode = _w3.eth.codec.encode_abi(
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
        "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B",
        "0xf11B8754eE6eC19c0c5e4bC682cF5095a5A9C350",
        get(data, 'discount'),
        get(data, 'cids'),
        get(data, 'types'),
        get(data, 'rarities'),
        get(data, 'deadline')
    ]
)
digest = Web3.solidityKeccak(['bytes'], [f'0x{_encode.hex()}'])
_signed_message = _w3.eth.account.signHash(
    digest,
    private_key=_privateKey
)


print("* Script test signature : ", _signed_message)
print("* API signature : ", _api_sig)
print({
    'v': str(_signed_message.v),
    'r': str(hex(_signed_message.r)),
    's': str(hex(_signed_message.s))
})



