// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {BaselineWallet} from "../src/BaselineWallet.sol";

contract BaselineWalletTest is Test {
    BaselineWallet wallet;

    uint256 ownerKey = 0xA11CE; // test-only key
    address owner;
    address bob = makeAddr("bob");
    address attacker = makeAddr("attacker");

    function setUp() public {
        owner = vm.addr(ownerKey);
        wallet = new BaselineWallet(owner);
        vm.deal(address(wallet), 10 ether); // fund the wallet with test ETH
    }

    /// Sign the wallet's current digest with `key` (65-byte r,s,v signature).
    function _sign(uint256 key, address to, uint256 amount) internal view returns (bytes memory) {
        bytes32 d = MessageHashUtils.toEthSignedMessageHash(wallet.digest(to, amount));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, d);
        return abi.encodePacked(r, s, v);
    }

    // ---------- legitimate use ----------

    function test_OwnerCanWithdraw() public {
        bytes memory sig = _sign(ownerKey, bob, 1 ether);
        wallet.withdraw(payable(bob), 1 ether, sig);
        assertEq(bob.balance, 1 ether);
        assertEq(wallet.ecdsaNonce(), 1);
    }

    function testFuzz_Withdraw(uint256 amount) public {
        amount = bound(amount, 0, 10 ether);
        bytes memory sig = _sign(ownerKey, bob, amount);
        wallet.withdraw(payable(bob), amount, sig);
        assertEq(bob.balance, amount);
        assertEq(address(wallet).balance, 10 ether - amount);
    }

    // ---------- rejected requests ----------

    function test_WrongKeyRejected() public {
        bytes memory sig = _sign(0xBAD, bob, 1 ether);
        vm.expectRevert(BaselineWallet.BadSignature.selector);
        wallet.withdraw(payable(bob), 1 ether, sig);
    }

    function test_ReplayRejected() public {
        bytes memory sig = _sign(ownerKey, bob, 1 ether);
        wallet.withdraw(payable(bob), 1 ether, sig);

        // Someone else resubmits the same public signature: nonce has moved on.
        vm.prank(attacker);
        vm.expectRevert(BaselineWallet.BadSignature.selector);
        wallet.withdraw(payable(bob), 1 ether, sig);
    }

    function test_ModifiedRecipientRejected() public {
        bytes memory sig = _sign(ownerKey, bob, 1 ether);
        vm.expectRevert(BaselineWallet.BadSignature.selector);
        wallet.withdraw(payable(attacker), 1 ether, sig);
    }

    // ---------- the point of the baseline ----------

    /// Simulated Q-day: the attacker holds a copy of ownerKey, so they ARE the owner.
    function test_CompromisedKeyAllowsTheft() public {
        bytes memory sig = _sign(ownerKey, attacker, 10 ether);
        vm.prank(attacker);
        wallet.withdraw(payable(attacker), 10 ether, sig);
        assertEq(attacker.balance, 10 ether);
        assertEq(address(wallet).balance, 0);
    }
}
