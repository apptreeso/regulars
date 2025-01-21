// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IAddressRegistry} from "../src/IAddressRegistry.sol";
import {Coins} from "../src/erc20/Coins.sol";
import {StockOptions} from "../src/erc20/StockOptions.sol";
import {Config} from "../src/Config.sol";

contract DeployCoins is Script {
    // Add custom error
    error UnsupportedChainId(uint256 chainId);
    
    IAddressRegistry addressRegistry;
    
    function run() external {
        console.log("\nStarting script... (Chain ID:", block.chainid, ")");

        // Get the correct address registry for the current chain
        address addressRegistryAddr = Config.getAddressRegistryForChain();
        addressRegistry = IAddressRegistry(addressRegistryAddr);
        
        address accessManagerAddr = addressRegistry.getAddress('AccessManager');

        vm.startBroadcast();

        // Deploy tokens
        Coins coins = new Coins(accessManagerAddr);
        StockOptions stocks = new StockOptions(accessManagerAddr);
        
        // Store token addresses in registry
        addressRegistry.set(address(coins), 'Coins');
        addressRegistry.set(address(stocks), 'StockOptions');
        
        vm.stopBroadcast();
    }
}