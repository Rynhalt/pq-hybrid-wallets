// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title BaselineWallet
/// @notice Control wallet: ECDSA-only authorization. Once the owner's ECDSA key
///         is compromised (our simulated Q-day), the attacker can drain it.
contract BaselineWallet {
    // Fixed labels baked into every signed message (no storage cost).
    bytes32 public constant TAG = keccak256("PQWallet.v1");
    uint8 public constant ACTION_WITHDRAW = 1;

    // Who may authorize withdrawals (set once at deploy).
    address public immutable owner;
    // Replay counter: goes up by one after every withdrawal.
    uint256 public ecdsaNonce;

    // Logged on success so tests and the harness can see what happened.
    event Withdrawn(uint256 indexed nonce, address indexed to, uint256 amount);

    // Cheap, exact failure reasons (tests match on these).
    error BadSignature();
    error SendFailed();

    // payable: the wallet can be funded in the deploy transaction.
    constructor(address _owner) payable {
        owner = _owner;
    }

    /// @notice Accept plain ETH deposits (e.g. migration transfers from an EOA).
    receive() external payable {}

    /// @notice The exact 32 bytes the owner signs for a withdrawal.
    /// @dev Binds wallet, chain, nonce, action, recipient and amount, so a
    ///      signature can't be replayed, moved to another wallet/chain, or edited.
    ///      Last field (next PQ key) is unused in the baseline, so it's zero.
    function digest(address to, uint256 amount) public view returns (bytes32) {
        return keccak256(
            abi.encode(TAG, address(this), block.chainid, ecdsaNonce, ACTION_WITHDRAW, to, amount, bytes32(0))
        );
    }

    /// @notice Anyone may submit; the owner's signature is what authorizes.
    function withdraw(address payable to, uint256 amount, bytes calldata sig) external {
        // 1. Checks: signature must come from the owner over this exact digest.
        //    (EIP-191 prefix = the format standard wallets sign.)
        bytes32 d = MessageHashUtils.toEthSignedMessageHash(digest(to, amount));
        if (ECDSA.recover(d, sig) != owner) revert BadSignature();

        // 2. Effects: bump the nonce BEFORE sending ETH (blocks replay + reentrancy).
        uint256 n = ecdsaNonce++;
        emit Withdrawn(n, to, amount);

        // 3. Interaction: send the ETH last; revert everything if it fails.
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert SendFailed();
    }
}
