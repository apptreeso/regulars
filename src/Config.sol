// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";

/// @title Config
/// @notice Contains common configuration constants and errors used across the protocol
library Config {
    // Chain ID constants
    uint256 constant BASE_CHAIN_ID = 8453;
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;

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

    function getWeth9() internal view returns (address) {
        Vm vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));
        return vm.envAddress('WETH9');
    }

    function getUniswapV3Factory() internal view returns (address) {
        Vm vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));
        return vm.envAddress('UNISWAP_V3_FACTORY');
    }
} 