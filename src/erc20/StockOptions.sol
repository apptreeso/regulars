// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract StockOptions is ERC20, ERC20Burnable, ERC20Pausable, AccessManaged, ERC20Permit {
    uint256 public constant MAX_SUPPLY = 10_000_000_000 * 10**18; // 10 billion tokens

    constructor(address initialAuthority)
        ERC20("Stock Options", "STOCKS")
        AccessManaged(initialAuthority)
        ERC20Permit("Stock Options")
    {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function pause() public restricted {
        _pause();
    }

    function unpause() public restricted {
        _unpause();
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
