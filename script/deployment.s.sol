// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../lib/forge-std/src/Script.sol";
import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {USDCoin} from '../contracts/USDC.sol';
import {WrappedBitcoin} from "../contracts/WBTC.sol";
import {WrappedETH} from "../contracts/WETH.sol";
import {Aero} from "../contracts/AERO.sol";
import {Solana} from "../contracts/SOL.sol";
import {Polygon} from "../contracts/POL.sol";
import {Mantra} from "../contracts/MANTRA.sol";
import {XucreIndexFunds} from "../contracts/XucreIndexFunds.sol";
import {PoolManager} from '../lib/v4-periphery/lib/v4-core/src/PoolManager.sol';

import {PositionManager} from "../lib/v4-periphery/src/PositionManager.sol";
import {PoolKey} from "../lib/v4-periphery/lib/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "../lib/v4-periphery/lib/v4-core/src/types/Currency.sol";
import {Actions} from "../lib/v4-periphery/src/libraries/Actions.sol";
import {LiquidityAmounts} from "../lib/v4-periphery/lib/v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "../lib/v4-periphery/lib/v4-core/src/libraries/TickMath.sol";
import {Constants22} from './base/Constants.sol';
import {Config} from './base/Config.sol';

//forge script script/deployment.s.sol:DeployXucre --fork-url http://localhost:8545 --broadcast --via-ir --optimize --optimizer-runs 200 -i 1
contract DeployXucre is Script, Constants22, Config {
    using CurrencyLibrary for Currency;
    // Constants from the original script
    //address private constant SWAP_ROUTER_ADDRESS = 0x96E3495b712c6589f1D2c50635FDE68CF17AC83c;
    //address private constant POOL_MANAGER_ADDRESS = 0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829;
    uint24 private constant POOL_FEE = 1000;

    function run() external {

        //vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        // Start broadcasting transaction
        //string deployerPrivateKey = vm.envString("DEVACCOUNTKEY");
        //vm.startBroadcast(deployerPrivateKey);
        vm.startBroadcast();
        // Get the signer address from environment variables
        address OWNER_ADDRESS = vm.envAddress("DEVACCOUNTADDRESS");

        // Interact with PoolManager if needed
        //PoolManager poolManager = PoolManager(POOLMANAGER.address);
        // Add token to PoolManager

        // Deploy XucreIndexFunds contract
        XucreIndexFunds xucre = new XucreIndexFunds(
            OWNER_ADDRESS,
            address(0x0),
            // Add swap router address
            address(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9),
            POOL_FEE
        );
        address xucreContract = address(xucre);

        console.log("XucreIndexFunds deployed at: ", xucreContract);

        // Verification script command
        console.log(
            string.concat(
                "Verification command: forge verify-contract --chain <network> --constructor-args ",
                vm.toString(OWNER_ADDRESS), " ",
                vm.toString(address(0x0)), " ",
                vm.toString(address(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9)), " ",
                vm.toString(POOL_FEE), " ",
                vm.toString(xucreContract),
                " XucreIndexFunds"
            )
        );

        

        // Stop broadcasting transaction
        vm.stopBroadcast();
    }

    
}

//forge script script/deployment.s.sol:DeployTokens --fork-url http://localhost:8545 --broadcast --via-ir --optimize --optimizer-runs 200 -i 1
contract DeployTokens is Script, Constants22, Config {
    using CurrencyLibrary for Currency;
    // Constants from the original script
    //address private constant SWAP_ROUTER_ADDRESS = 0x96E3495b712c6589f1D2c50635FDE68CF17AC83c;
    //address private constant POOL_MANAGER_ADDRESS = 0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829;
    uint24 private constant POOL_FEE = 1000;

    /////////////////////////////////////
    // --- Parameters to Configure --- //
    /////////////////////////////////////

    // --- pool configuration --- //
    // fees paid by swappers that accrue to liquidity providers
    uint24 lpFee = 3000; // 0.30%
    int24 tickSpacing = 60;

    // starting price of the pool, in sqrtPriceX96
    uint160 startingPrice = 79228162514264337593543950336; // floor(sqrt(1) * 2^96)

    // --- liquidity position configuration --- //
    uint256 public token0Amount = 1e2;
    uint256 public token1Amount = 1e16;

    // range of the position
    int24 tickLower = -600; // must be a multiple of tickSpacing
    int24 tickUpper = 600;
    /////////////////////////////////////

    function run() external {
      //vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      vm.startBroadcast();
        // Get the signer address from environment variables
        //address OWNER_ADDRESS = vm.envAddress("DEVACCOUNTADDRESS");

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

        Solana solana = new Solana();
        address solanaContract = address(solana);

        Polygon polygon = new Polygon();
        address polygonContract = address(polygon);

        // Log deployed token addresses
        console.log("USDC: ", usdcContract);
        console.log("WBTC: ", wbtcContract);
        console.log("WETH: ", wethContract);
        console.log("AERO: ", aeroContract);
        console.log("MANTRA: ", mantraContract);
        console.log("SOL: ", solanaContract);
        console.log("POL: ", polygonContract);
        vm.stopBroadcast();
    }    
}

//forge script script/deployment.s.sol:DeployLps --fork-url http://localhost:8545 --broadcast --via-ir --optimize --optimizer-runs 200 -i 1
contract DeployLps is Script, Constants22, Config {
    using CurrencyLibrary for Currency;
    // Constants from the original script
    //address private constant SWAP_ROUTER_ADDRESS = 0x96E3495b712c6589f1D2c50635FDE68CF17AC83c;
    //address private constant POOL_MANAGER_ADDRESS = 0x7Da1D65F8B249183667cdE74C5CBD46dD38AA829;
    uint24 private constant POOL_FEE = 1000;

    /////////////////////////////////////
    // --- Parameters to Configure --- //
    /////////////////////////////////////

    // --- pool configuration --- //
    // fees paid by swappers that accrue to liquidity providers
    uint24 lpFee = 3000; // 0.30%
    int24 tickSpacing = 60;

    // starting price of the pool, in sqrtPriceX96
    uint160 startingPrice = 79228162514264337593543950336; // floor(sqrt(1) * 2^96)

    // --- liquidity position configuration --- //
    uint256 public token0Amount = 1000000000;
    uint256 public token1Amount = 1000000000;

    // range of the position
    int24 tickLower = -600; // must be a multiple of tickSpacing
    int24 tickUpper = 600;
    /////////////////////////////////////

    function createPair(Currency currency0, Currency currency1, IERC20 token1) internal {

        console.log("Testing logging in create pair ");
        PoolKey memory pool = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });
        bytes memory hookData = new bytes(0);

        // --------------------------------- //

        // Converts token amounts to liquidity units
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            startingPrice,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            token0Amount,
            token1Amount
        );

        // slippage limits
        uint256 amount0Max = token0Amount + 1 wei;
        uint256 amount1Max = token1Amount + 1 wei;

        (bytes memory actions, bytes[] memory mintParams) =
            _mintLiquidityParams(pool, tickLower, tickUpper, liquidity, amount0Max, amount1Max, address(this), hookData);

        // multicall parameters
        bytes[] memory params = new bytes[](2);

        // initialize pool
        params[0] = abi.encodeWithSelector(posm.initializePool.selector, pool, startingPrice, hookData);

        // mint liquidity
        params[1] = abi.encodeWithSelector(
            posm.modifyLiquidities.selector, abi.encode(actions, mintParams), block.timestamp + 60
        );

        // if the pool is an ETH pair, native tokens are to be transferred
        uint256 valueToPass = currency0.isAddressZero() ? amount0Max : 0;
        
        vm.startBroadcast();
        tokenApprovals(currency0, currency1, token1);
        
        vm.stopBroadcast();
        // multicall to atomically create pool & add liquidity
        vm.broadcast();
        posm.multicall{value: valueToPass}(params);
    }

    function _mintLiquidityParams(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 liquidity,
        uint256 amount0Max,
        uint256 amount1Max,
        address recipient,
        bytes memory hookData
    ) internal pure returns (bytes memory, bytes[] memory) {
        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(poolKey, _tickLower, _tickUpper, liquidity, amount0Max, amount1Max, recipient, hookData);
        params[1] = abi.encode(poolKey.currency0, poolKey.currency1);
        return (actions, params);
    }

    function tokenApprovals(Currency currency0, Currency currency1, IERC20 token1) public {
        if (!currency0.isAddressZero()) {
            IERC20(Currency.unwrap(currency0)).approve(address(posm), type(uint256).max);
            //token0.approve(address(PERMIT2), type(uint256).max);
            PERMIT2.approve(Currency.unwrap(currency0), address(posm), type(uint160).max, type(uint48).max);
        }
        if (!currency1.isAddressZero()) {
            IERC20(Currency.unwrap(currency1)).approve(address(PERMIT2), type(uint256).max);
            PERMIT2.approve(Currency.unwrap(currency1), address(posm), type(uint160).max, type(uint48).max);
        }
        return;
    }

    function run() external {

          //vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
          //IERC20 token_source = IERC20(address(0x0));

          IERC20 token_WBTC = IERC20(address(0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e));
          IERC20 token_WETH = IERC20(address(0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0));
          IERC20 token_AERO = IERC20(address(0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82));
          IERC20 token_MANTRA = IERC20(address(0x9A676e781A523b5d0C0e43731313A708CB607508));
          IERC20 token_SOL = IERC20(address(0x0B306BF915C4d645ff596e518fAf3F9669b97016));
          IERC20 token_POL = IERC20(address(0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1));
          Currency currency_source = Currency.wrap(address(0x0));
          Currency currency_WBTC = Currency.wrap(address(token_WBTC));
          Currency currency_WETH = Currency.wrap(address(token_WETH));
          Currency currency_AERO = Currency.wrap(address(token_AERO));
          Currency currency_MANTRA = Currency.wrap(address(token_MANTRA));
          Currency currency_SOL = Currency.wrap(address(token_SOL));
          Currency currency_POL = Currency.wrap(address(token_POL));
        
          createPair(currency_source, currency_WBTC, token_WBTC);
          // createPair(currency_source, currency_WETH, token_WETH);
          // createPair(currency_source, currency_AERO, token_AERO);
          // createPair(currency_source, currency_MANTRA, token_MANTRA);
          // createPair(currency_source, currency_SOL, token_SOL);
          // createPair(currency_source, currency_POL, token_POL);
          
    }    
}
