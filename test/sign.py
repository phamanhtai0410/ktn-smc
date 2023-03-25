from web3 import Web3
from pydash import get


_privateKey = "98102796d0dfe116f5af6e9a3c10dc38d316f6c98b3ded8d008b962c7d126460"

_user_address = "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B"

_contract_address = "0x5cEc77CeE391b2104DB264F74cdE3CC4a4b1B9ee"

_nft_collection_address = "0x3c4dCA37943cbAEe5cE5766a16473dBb09670d01"

_data = {
    "discount": 10 ** 16,
    # "rarities": [
    #     0
    # ],
    # "meshIndexes": [
    #     0
    # ],
    # "meshMaterialIndexes": [
    #     0
    # ],
    "deadline": 1679815126
}

def generate_signature():
    _w3 = Web3()
    _encode = _w3.codec.encode_abi(
        [
            'uint256', # chain
            'address', # _user_address
            'address', # contract creator
            'address', # nft address
            'uint256', # discount
            'bool', # is whitelist
            'uint256[]', #_nftIndexes
            'uint256' # deadline
        ],  # [chain_id, user_address, contract_address, nft_address,discount, cids, types, rarities, deadline]
        [
            97,
            _user_address,
            _contract_address,
            _nft_collection_address,
            get(_data, "discount"),
            False,
            [0],
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

# abi.encode(
#                 getChainID(),
#                 msg.sender,
#                 address(this),
#                 _nftCollection,
#                 _discount,
#                 _isWhitelistMint,
#                 _nftIndexes,
#                 _proof.deadline
#             )