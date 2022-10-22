import web3
from web3 import Web3


# hex_str = web3.Web3.toHex(bytes("hello", "utf-8"))
# print(hex_str)
# hex_int = int(hex_str, 16)
# print("Solution1 : {0:<#0{1}x}".format(hex_int, 64))
# padding = 64
# print(f"Solution2 : {hex_int:<#0{padding}x}")

_w3 = Web3()
_base_message = Web3.solidityKeccak(
    [
        97,
        "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B",
        "0x29E754233F6A50ee5AE3ee6A0217aD907dc3386B",
        0,
        ["bafkreifiuytiisforeksrt3aw3itv3ajc6wsxm6pvknawoj3nk5t2tm64e"],
        [1],
        [1],
        1666413347
    ]
)

_signed_message = _w3.eth.account.signHash(
    _base_message,
    private_key="98102796d0dfe116f5af6e9a3c10dc38d316f6c98b3ded8d008b962c7d126460"
)

print(_signed_message)

print({
    'v': str(_signed_message.v),
    'r': str(hex(_signed_message.r)),
    's': str(hex(_signed_message.s))
})



