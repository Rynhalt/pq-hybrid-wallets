// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BaselineWallet} from "../src/BaselineWallet.sol";

/// Deploys a BaselineWallet funded with 1 ETH, owned by the deployer.
/// Usage (with `anvil` running in another terminal):
///   PRIVATE_KEY=<anvil test key> forge script script/DeployBaseline.s.sol \
///     --rpc-url http://127.0.0.1:8545 --broadcast
/// Without --broadcast it's a dry run (simulates, sends nothing).
contract DeployBaseline is Script {
    // Entry point: forge script calls run() automatically.
    function run() external {
        // Read the key from the environment (never hard-code keys);
        // its address becomes the wallet's owner.
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerKey);

        // Everything between start/stopBroadcast is signed with deployerKey
        // and sent as a real transaction to the --rpc-url chain.
        vm.startBroadcast(deployerKey);
        BaselineWallet wallet = new BaselineWallet{value: 1 ether}(owner); // deploy + fund in one tx
        vm.stopBroadcast();

        // Print the address so we can use it with cast (balance, withdraw, ...).
        console.log("BaselineWallet deployed at:", address(wallet));
        console.log("Owner:", owner);
    }
}
