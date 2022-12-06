from web3 import Web3
from pydash import get


_privateKey = "693292bf46155b4fbdc0926db88c2228ac8b434207ce289309d8fef1f9457cf3"
_user_address = "0x183Ff214179cd2B1c06A937D663F192340edd159"
_contract_address = "0x111160bd05e5215edA15a4151DC07a380E7ACd61" # box creator
_collection_address = "0xA1BD1fF005380b5db73CC5e0BC68A384C4a9EB0c" # box

_data = {
    "discount": 684000000000000000000,
    "deadline": 1668760908,
    "amount": 1
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
            'uint256',
            'uint256'
        ],  # [chain_id, user_address, contract_address, collection_address, discount, amount, deadline]
        [
            97,
            _user_address,
            _contract_address,
            _collection_address,
            get(_data, "discount"),
            get(_data, "amount"),
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
