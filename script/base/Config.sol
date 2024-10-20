// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "../../lib/forge-std/src/interfaces/IERC20.sol";
import {IHooks} from "../../lib/v4-periphery/lib/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "../../lib/v4-periphery/lib/v4-core/src/types/Currency.sol";

/// @notice Shared configuration between scripts
contract Config {
    /// @dev populated with default anvil addresses
    IHooks constant hookContract = IHooks(address(0x0));

}