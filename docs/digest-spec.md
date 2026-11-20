# Digest specification (draft, to be agreed by the group)

Every signed action, ECDSA or post-quantum, signs this 32-byte digest:

```
digest = keccak256(abi.encode(TAG, wallet, chainId, nonce, action, to, amount, next))
```

| Field | Type | Value / why |
| --- | --- | --- |
| `TAG` | bytes32 | `keccak256("PQWallet.v1")`: version and domain separation |
| `wallet` | address | `address(this)`: no replay across our four wallets |
| `chainId` | uint256 | `block.chainid`: no replay between Anvil (31337) and Sepolia |
| `nonce` | uint256 | `ecdsaNonce` for ECDSA actions; `0` for PQ-only actions (bound by the commitment instead) |
| `action` | uint8 | 1 WITHDRAW, 2 QUEUE, 3 CANCEL, 4 FREEZE, 5 RECOVER, 6 MIGRATE |
| `to` | address | recipient |
| `amount` | uint256 | wei |
| `next` | bytes32 | next PQ public key commitment; `0` for ECDSA-only actions |

- ECDSA signs the EIP-191 form: `MessageHashUtils.toEthSignedMessageHash(digest)`.
- The post-quantum signature signs the raw `digest`.
- Python must produce byte-identical digests (use `eth_abi.encode` with the same types in the same order). Shared test vectors in `test/vectors/` check this.
