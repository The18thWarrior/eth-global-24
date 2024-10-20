// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {USDCoin} from '../contracts/USDC.sol';
import {WrappedBitcoin} from "../contracts/WBTC.sol";
import {WrappedETH} from "../contracts/WETH.sol";
import {Aero} from "../contracts/AERO.sol";
import {Mantra} from "../contracts/MANTRA.sol";
import {XucreIndexFunds} from "../contracts/XucreIndexFunds.sol";
import {PoolManager} from '../lib/v4-core/src/PoolManager.sol';

contract DeployTokensAndXucre is Script {
    // Constants from the original script
    address private constant SWAP_ROUTER_ADDRESS = 0x96E3495b712c6589f1D2c50635FDE68CF17AC83c;
    address private constant POOL_MANAGER_ADDRESS = 0x7da1d65f8b249183667cde74c5cbd46dd38aa829;
    uint256 private constant POOL_FEE = 1000;

    function run() external {
        // Start broadcasting transaction
        vm.startBroadcast();

        // Get the signer address from environment variables
        address DEV_ACCOUNT_ADDRESS = vm.envAddress("DEVACCOUNTADDRESS");
        address OWNER_ADDRESS = vm.envAddress("DEVACCOUNTADDRESS");

        // Deploy tokens
        USDCoin usdc = new USDCoin();
        address usdcContract = address(usdc);

        WrappedBitcoin wbtc = new WrappedBitcoin();
        address wbtcContract = address(wbtc);

        WrappedETH weth = new WrappedETH();
        address wethContract = address(weth);

        Aero aero = new Aero();
        address aeroContract = address(aero);

        Mantra mantra = new Mantra();
        address mantraContract = address(mantra);

        // Log deployed token addresses
        console.log("USDC: ", usdcContract);
        console.log("WBTC: ", wbtcContract);
        console.log("WETH: ", wethContract);
        console.log("AERO: ", aeroContract);
        console.log("MANTRA: ", mantraContract);

        // Interact with PoolManager if needed
        PoolManager poolManager = PoolManager(POOL_MANAGER_ADDRESS);

        // Deploy XucreIndexFunds contract
        XucreIndexFunds xucre = new XucreIndexFunds(
            OWNER_ADDRESS,
            usdcContract,
            SWAP_ROUTER_ADDRESS,
            POOL_FEE
        );
        address xucreContract = address(xucre);

        console.log("XucreIndexFunds deployed at: ", xucreContract);

        // Verification script command
        console.log(
            string.concat(
                "Verification command: forge verify-contract --chain <network> --constructor-args ",
                vm.toString(OWNER_ADDRESS), " ",
                usdcContract, " ",
                vm.toString(SWAP_ROUTER_ADDRESS), " ",
                vm.toString(POOL_FEE), " ",
                xucreContract,
                " XucreIndexFunds"
            )
        );

        // Stop broadcasting transaction
        vm.stopBroadcast();
    }
}
