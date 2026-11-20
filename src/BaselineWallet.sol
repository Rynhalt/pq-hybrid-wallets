// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title BaselineWallet
/// @notice Control wallet: ECDSA-only authorization. Once the owner's ECDSA key
///         is compromised (our simulated Q-day), the attacker can drain it.
/// @dev Uses the shared digest layout from docs/digest-spec.md so the other
///      three wallets can reuse the same signing code.
contract BaselineWallet {
    bytes32 public constant TAG = keccak256("PQWallet.v1");
    uint8 public constant ACTION_WITHDRAW = 1;

    address public immutable owner;
    uint256 public ecdsaNonce;

    event Withdrawn(uint256 indexed nonce, address indexed to, uint256 amount);

    error BadSignature();
    error SendFailed();

    constructor(address _owner) payable {
        owner = _owner;
    }

    /// @notice Accept deposits (e.g. migration transfers from an EOA).
    receive() external payable {}

    /// @notice The exact 32 bytes the owner signs for a withdrawal.
    function digest(address to, uint256 amount) public view returns (bytes32) {
        return keccak256(
            abi.encode(TAG, address(this), block.chainid, ecdsaNonce, ACTION_WITHDRAW, to, amount, bytes32(0))
        );
    }

    /// @notice Anyone may submit; the signature is what authorizes.
    function withdraw(address payable to, uint256 amount, bytes calldata sig) external {
        // 1. Checks
        bytes32 d = MessageHashUtils.toEthSignedMessageHash(digest(to, amount));
        if (ECDSA.recover(d, sig) != owner) revert BadSignature();

        // 2. Effects
        uint256 n = ecdsaNonce++;
        emit Withdrawn(n, to, amount);

        // 3. Interaction
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert SendFailed();
    }
}
