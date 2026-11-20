// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BaselineWallet} from "../src/BaselineWallet.sol";

/// Usage (with `anvil` running in another terminal):
///   forge script script/DeployBaseline.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
/// PRIVATE_KEY must be set (see README: use one of Anvil's printed test keys).
contract DeployBaseline is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);
        BaselineWallet wallet = new BaselineWallet{value: 1 ether}(owner);
        vm.stopBroadcast();

        console.log("BaselineWallet deployed at:", address(wallet));
        console.log("Owner:", owner);
    }
}
