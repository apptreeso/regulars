// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IAddressRegistry} from "../src/IAddressRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Config} from "../src/Config.sol";

contract CheckBalance is Script {
    IAddressRegistry addressRegistry;

    function run() external {
        console.log("\nChecking balances for address:", msg.sender);

        // Get the correct address registry for the current chain
        address addressRegistryAddr = Config.getAddressRegistryForChain();
        addressRegistry = IAddressRegistry(addressRegistryAddr);

        // Get token addresses
        address coinsAddr = addressRegistry.getAddress('Coins');
        address stocksAddr = addressRegistry.getAddress('StockOptions');

        // Get token balances
        uint256 coinsBalance = IERC20(coinsAddr).balanceOf(msg.sender);
        uint256 stocksBalance = IERC20(stocksAddr).balanceOf(msg.sender);

        // Log balances
        console.log("Coins balance:", coinsBalance);
        console.log("StockOptions balance:", stocksBalance);
    }
}
