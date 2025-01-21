// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";

/// @title Config
/// @notice Contains common configuration constants and errors used across the protocol
library Config {
    // Chain ID constants
    uint256 constant BASE_CHAIN_ID = 8453;
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;

    // Contract addresses
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // Custom errors
    error UnsupportedChainId(uint256 chainId);

    /// @notice Gets the address registry address for the current chain
    /// @return The address of the registry for the current chain
    function getAddressRegistryForChain() internal view returns (address) {
        Vm vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
        
        if (block.chainid == BASE_CHAIN_ID) {
            return vm.envAddress("BASE_ADDRESS_REGISTRY");
        } else if (block.chainid == BASE_SEPOLIA_CHAIN_ID) {
            return vm.envAddress("BASE_SEPOLIA_ADDRESS_REGISTRY");
        } else {
            revert UnsupportedChainId(block.chainid);
        }
    }

    function getWeth9() internal pure returns (address) {
        return WETH;
    }

    function getUniswapV3Factory() internal pure returns (address) {
        return UNISWAP_V3_FACTORY;
    }
} 