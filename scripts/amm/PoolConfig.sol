// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library PoolConfig {
    // Pool fees
    uint24 public constant POOL_FEE = 3000; // 0.3% fee tier
    
    // Initial prices in terms of tokens per ETH
    uint256 public constant COINS_PRICE = 8e13;  // 80,000 COINS per 1 ETH (for 1e27 total supply)
    uint256 public constant STOCKS_PRICE = 8e14;  // 800,000 STOCKS per 1 ETH (for 1e28 total supply)

    // Tick ranges
    // int24 public constant MIN_TICK = -887272;
    // int24 public constant MAX_TICK = -MIN_TICK;

    // Tick spacing for 0.3% is 60, so pick multiples of 60:
    int24 public constant MIN_TICK = -887220; // instead of -887272
    int24 public constant MAX_TICK =  887220; // instead of  887272

    // Using half of 0.001 ETH for each pool
    uint256 constant LIQUIDITY_AMOUNT = 5e14; // 0.0005 ETH
} 