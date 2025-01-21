// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Config} from "../../src/Config.sol";
import {IAddressRegistry} from "../../src/IAddressRegistry.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {PoolConfig} from "./PoolConfig.sol";

contract InitiatePools is Script {
    IAddressRegistry addressRegistry;

    // Use the library's constants
    uint24 public constant POOL_FEE = PoolConfig.POOL_FEE;
    uint256 public constant COINS_PRICE = PoolConfig.COINS_PRICE;
    uint256 public constant STOCKS_PRICE = PoolConfig.STOCKS_PRICE;

    // Helper function to calculate sqrtPriceX96
    function calculateSqrtPriceX96(uint256 price) internal pure returns (uint160) {
        // price is now in tokens/ETH
        // We need ETH/token price = 1/price
        uint256 ethPerToken = 1e18 / price;  // Use 1e18 for precision
        uint256 sqrtPrice = Math.sqrt(ethPerToken * (1e18));
        return uint160((sqrtPrice * (1 << 96)) / Math.sqrt(1e18));
    }

    function run() external {
        console.log("\n=== Initiating Pools Script ===");
        console.log("Chain ID:", block.chainid);
        printMyInfo();

        // Initialize configs - using static method instead of creating new instance
        address addressRegistryAddr = Config.getAddressRegistryForChain();
        addressRegistry = IAddressRegistry(addressRegistryAddr);
        
        console.log("\n=== Configuration ===");
        console.log("POOL_FEE:\t", POOL_FEE);
        console.log("COINS_PRICE:\t", COINS_PRICE);
        console.log("STOCKS_PRICE:\t", STOCKS_PRICE);

        vm.startBroadcast();

        // Get token addresses
        address coinsAddr = addressRegistry.getAddress('Coins');
        address stocksAddr = addressRegistry.getAddress('StockOptions');
        console.log("\n=== Token Addresses ===");
        console.log("Coins Token:", coinsAddr);
        console.log("Stocks Token:", stocksAddr);
        console.log("WETH:", Config.getWeth9());
        
        // Create pools and initialize
        IUniswapV3Factory factory = IUniswapV3Factory(Config.getUniswapV3Factory());
        console.log("Uniswap Factory:", address(factory));

        // Get existing pools
        address coinsWethPool = factory.getPool(coinsAddr, Config.getWeth9(), POOL_FEE);
        address stocksWethPool = factory.getPool(stocksAddr, Config.getWeth9(), POOL_FEE);
        
        // Calculate sqrt prices
        uint160 coinsSqrtPrice = calculateSqrtPriceX96(COINS_PRICE);
        uint160 stocksSqrtPrice = calculateSqrtPriceX96(STOCKS_PRICE);
        console.log("\n=== Price Information ===");
        console.log("Coins sqrt price:", uint256(coinsSqrtPrice));
        console.log("Stocks sqrt price:", uint256(stocksSqrtPrice));

        console.log("\n=== Pool Operations ===");
        
        // Create and initialize COINS/WETH pool
        address token0 = coinsAddr < Config.getWeth9() ? coinsAddr : Config.getWeth9();
        address token1 = coinsAddr < Config.getWeth9() ? Config.getWeth9() : coinsAddr;
        coinsWethPool = factory.createPool(token0, token1, POOL_FEE);
        IUniswapV3Pool(coinsWethPool).initialize(coinsSqrtPrice);
        console.log("[SUCCESS] Created and initialized new COINS/WETH pool at:", coinsWethPool);

        // Create and initialize STOCKS/WETH pool
        token0 = stocksAddr < Config.getWeth9() ? stocksAddr : Config.getWeth9();
        token1 = stocksAddr < Config.getWeth9() ? Config.getWeth9() : stocksAddr;
        stocksWethPool = factory.createPool(token0, token1, POOL_FEE);
        IUniswapV3Pool(stocksWethPool).initialize(stocksSqrtPrice);
        console.log("[SUCCESS] Created and initialized new STOCKS/WETH pool at:", stocksWethPool);
        
        console.log("\n=== Final Pool Addresses ===");
        console.log("COINS/WETH pool:", coinsWethPool);
        console.log("STOCKS/WETH pool:", stocksWethPool);

        console.log("\n=== Updating Address Registry ===");
        // Store pool addresses in registry
        addressRegistry.set(coinsWethPool, 'CoinsWethPool');
        addressRegistry.set(stocksWethPool, 'StocksWethPool');
        console.log("Pool addresses stored in registry");
        
        vm.stopBroadcast();
        console.log("\n=== Script Completed ===");
    }

    function printMyInfo() public view {
        console.log(msg.sender, "msg.sender");
        console.log(address(this), "address(this)");
    }
}