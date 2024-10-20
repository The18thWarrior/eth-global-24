// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PoolManager} from "../../lib/v4-periphery/lib/v4-core/src/PoolManager.sol";
import {PositionManager} from "../../lib/v4-periphery/src/PositionManager.sol";
import {IAllowanceTransfer} from "../../lib/v4-periphery/lib/permit2/src/interfaces/IAllowanceTransfer.sol";
import {PoolSwapTest} from "../../lib/v4-periphery/lib/v4-core/src/test/PoolSwapTest.sol";

/// @notice Shared constants used in scripts
contract Constants22 {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    /// @dev populated with default anvil addresses
    PoolManager constant POOLMANAGER = PoolManager(address(0x5FC8d32690cc91D4c39d9d3abcBD16989F875707));
    PositionManager constant posm = PositionManager(address(0x0165878A594ca255338adfa4d48449f69242Eb8F));
    IAllowanceTransfer constant PERMIT2 = IAllowanceTransfer(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
    PoolSwapTest constant SWAP_ROUTER = PoolSwapTest(address(0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6));
}