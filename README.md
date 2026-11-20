# Hybrid Ethereum Wallets for Post-Quantum Security and Secure Migration

CS559 Blockchains group project. Team: HsiangEn Liu, Marcus Izumi, Asya Dente.

We implement and compare four smart contract wallets under a simulated ECDSA
compromise ("Q-day"): an ECDSA-only baseline, an always-hybrid wallet
(ECDSA + hash-based signature), a wallet with a post-quantum recovery key, and a
wallet with time-delayed withdrawals that the post-quantum key can cancel. We
also study migrating funds from an EOA into a protected wallet before and after
Q-day.

## Repository layout

| Path | What lives there | Owner |
| --- | --- | --- |
| `src/` | Solidity wallets and the hash-based verifier | Marcus (wallets), Asya (verifier) |
| `test/` | Foundry tests; `test/vectors/` holds shared test vectors (JSON) | everyone |
| `script/` | Deployment and migration scripts (`forge script`) | Marcus + Asya |
| `signer/` | Python off-chain signer (key generation, signing, used-key tracking) | HsiangEn |
| `harness/` | Attack scenarios, transaction ordering on Anvil, gas collection | HsiangEn |
| `docs/` | Digest spec, threat model, findings | everyone |

## Setup

1. Install Foundry: `curl -L https://foundry.paradigm.xyz | bash`, open a new terminal, then `foundryup`.
2. Install dependencies (from the repo root): `forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts`
3. Build and test: `forge build` then `forge test -vv`

## Everyday commands

| Command | What it does |
| --- | --- |
| `forge test -vv` | Run all tests (more `v`s = more detail, `-vvvv` shows full call traces) |
| `forge test --match-test test_ReplayRejected -vvvv` | Run one test with a trace |
| `forge test --gas-report` | Per-function execution gas (excludes calldata and the 21k base cost) |
| `anvil` | Start a local chain at http://127.0.0.1:8545 with 10 funded test accounts |
| `anvil --no-mining` | Local chain that only mines when told to (for transaction-ordering experiments) |
| `cast receipt <txhash>` | Full receipt; `gasUsed` is the number we report |

## Rules

- **Never commit real private keys.** Tests use hard-coded test keys; scripts read `PRIVATE_KEY` from your environment. Anvil's printed keys are public and only safe on a local chain.
- All signed messages follow `docs/digest-spec.md`. Change it only with group agreement.
- Credit any reused code (e.g. poqeth, SPHINCS-) in comments and in the report.
