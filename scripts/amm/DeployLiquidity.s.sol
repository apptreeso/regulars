// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IAddressRegistry} from "../../src/IAddressRegistry.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {PoolConfig} from "./PoolConfig.sol";
import {Config} from "../../src/Config.sol";

interface IPositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );
}

interface IWETH9 {
    function deposit() external payable;
}

contract DeployLiquidity is Script {
    IAddressRegistry addressRegistry;
    IPositionManager positionManager;

    function run() external {
        console.log("\nStarting script... (", block.chainid, ")");
        printMyInfo();

        // Get the correct address registry for the current chain
        address addressRegistryAddr = Config.getAddressRegistryForChain();
        addressRegistry = IAddressRegistry(addressRegistryAddr);

        vm.startBroadcast();

        setupWETHAndApprovals();
        initializePoolsIfNeeded();
        mintLiquidityPositions();

        vm.stopBroadcast();
    }

    function setupWETHAndApprovals() internal {
        console.log("Depositing ETH to get WETH...");
        address weth = addressRegistry.getAddress('WETH9');
        IWETH9(weth).deposit{value: 2 * PoolConfig.LIQUIDITY_AMOUNT}();

        // Create and initialize nonfungible position manager
        address positionManagerAddr = addressRegistry.getAddress('NonfungiblePositionManager');
        positionManager = IPositionManager(positionManagerAddr);        
        console.log(address(positionManager), "Nonfungible position manager");

        // Approve tokens
        address coinsAddr = addressRegistry.getAddress('Coins');
        address stocksAddr = addressRegistry.getAddress('StockOptions');
        IERC20(coinsAddr).approve(address(positionManager), PoolConfig.LIQUIDITY_AMOUNT * PoolConfig.COINS_PRICE);
        IERC20(stocksAddr).approve(address(positionManager), PoolConfig.LIQUIDITY_AMOUNT * PoolConfig.STOCKS_PRICE);
        IERC20(weth).approve(address(positionManager), 2 * PoolConfig.LIQUIDITY_AMOUNT);
    }

    function initializePoolsIfNeeded() internal {
        address coinsWethPool = addressRegistry.getAddress('CoinsWethPool');
        address stocksWethPool = addressRegistry.getAddress('StocksWethPool');

        (uint160 sqrtPriceX96Coins, int24 tickCurrentCoins, , , , , bool initializedCoins) = IUniswapV3Pool(coinsWethPool).slot0();
        (uint160 sqrtPriceX96Stocks, int24 tickCurrentStocks, , , , , bool initializedStocks) = IUniswapV3Pool(stocksWethPool).slot0();
        
        if (!initializedCoins) {
            uint160 initialSqrtPriceX96 = calculateSqrtPriceX96(PoolConfig.COINS_PRICE);
            IUniswapV3Pool(coinsWethPool).initialize(initialSqrtPriceX96);
            console.log("Initialized COINS pool with sqrtPriceX96:", initialSqrtPriceX96);
        }

        if (!initializedStocks) {
            uint160 initialSqrtPriceX96 = calculateSqrtPriceX96(PoolConfig.STOCKS_PRICE);
            IUniswapV3Pool(stocksWethPool).initialize(initialSqrtPriceX96);
            console.log("Initialized STOCKS pool with sqrtPriceX96:", initialSqrtPriceX96);
        }
    }

    function mintLiquidityPositions() internal {
        mintCoinsWethPosition();
        mintStocksWethPosition();
    }

    function mintCoinsWethPosition() internal {
        address coinsAddr = addressRegistry.getAddress('Coins');
        address weth = addressRegistry.getAddress('WETH9');

        uint256 wethAmount = PoolConfig.LIQUIDITY_AMOUNT; // 0.0005 ETH
        // Use less than half of COINS supply (1e27/2)
        uint256 coinsAmount = 4e26; // Less than half of 1e27
        
        console.log("WETH amount:", wethAmount);
        console.log("COINS amount:", coinsAmount);
        
        // Approve exact amounts
        IERC20(weth).approve(address(positionManager), wethAmount);
        IERC20(coinsAddr).approve(address(positionManager), coinsAmount);

        (address token0, address token1) = weth < coinsAddr ? 
            (weth, coinsAddr) : 
            (coinsAddr, weth);
        
        (uint256 amount0Desired, uint256 amount1Desired) = weth < coinsAddr ? 
            (wethAmount, coinsAmount) : 
            (coinsAmount, wethAmount);

        IPositionManager.MintParams memory params = IPositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: PoolConfig.POOL_FEE,
            tickLower: PoolConfig.MIN_TICK,
            tickUpper: PoolConfig.MAX_TICK,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 60
        });

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = 
            positionManager.mint(params);
        console.log("Minted COINS/WETH liquidity:", liquidity);

        handleRefunds(params.token0, params.token1, params.amount0Desired, params.amount1Desired, amount0, amount1);
    }

    function mintStocksWethPosition() internal {
        address stocksAddr = addressRegistry.getAddress('StockOptions');
        address weth = addressRegistry.getAddress('WETH9');

        uint256 wethAmount = PoolConfig.LIQUIDITY_AMOUNT; // 0.0005 ETH
        // Use less than half of STOCKS supply (1e28/2)
        uint256 stocksAmount = 4e27; // Less than half of 1e28
        
        console.log("WETH amount:", wethAmount);
        console.log("STOCKS amount:", stocksAmount);

        // Approve exact amounts
        IERC20(weth).approve(address(positionManager), wethAmount);
        IERC20(stocksAddr).approve(address(positionManager), stocksAmount);

        (address token0, address token1) = weth < stocksAddr ? 
            (weth, stocksAddr) : 
            (stocksAddr, weth);
        
        (uint256 amount0Desired, uint256 amount1Desired) = weth < stocksAddr ? 
            (wethAmount, stocksAmount) : 
            (stocksAmount, wethAmount);

        IPositionManager.MintParams memory params = IPositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: PoolConfig.POOL_FEE,
            tickLower: PoolConfig.MIN_TICK,
            tickUpper: PoolConfig.MAX_TICK,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 60
        });

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = 
            positionManager.mint(params);
        console.log("Minted STOCKS/WETH liquidity:", liquidity);

        handleRefunds(params.token0, params.token1, params.amount0Desired, params.amount1Desired, amount0, amount1);
    }

    function handleRefunds(
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0,
        uint256 amount1
    ) internal {
        if (amount0 < amount0Desired) {
            IERC20(token0).approve(address(positionManager), 0);
            uint256 refund0 = amount0Desired - amount0;
            IERC20(token0).transfer(msg.sender, refund0);
        }
        if (amount1 < amount1Desired) {
            IERC20(token1).approve(address(positionManager), 0);
            uint256 refund1 = amount1Desired - amount1;
            IERC20(token1).transfer(msg.sender, refund1);
        }
    }

    function printMyInfo() public view {
        console.log(msg.sender, "msg.sender");
        console.log(address(this), "address(this)");
    }

    function calculateSqrtPriceX96(uint256 price) internal pure returns (uint160) {
        // Convert price to sqrt(price/1e18) * 2^96
        uint256 sqrtPrice = Math.sqrt(price / 1e18) * (1 << 96);
        return uint160(sqrtPrice);
    }
}