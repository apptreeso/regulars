// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Address Registry Interface
/// @notice Interface for the AddressRegistry contract
interface IAddressRegistry {
    /// @notice Struct containing all information about a registered account
    struct Account {
        address addr;
        string name;
        string category;
    }

    /// @notice Gets just the address associated with a name
    function getAddress(string calldata name) external view returns (address);
    
    /// @notice Sets or updates an account's registration
    function set(address addr, string calldata name) external;

    /// @notice Updates the category for a name
    function updateCategory(string calldata name, string calldata category) external;

    /// @notice The name is not found in the registry
    error NameNotFound(string name);
    /// @notice The address is already registered with a different name
    error AddressAlreadyRegistered(address addr, string currentName);
}
