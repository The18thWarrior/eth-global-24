
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
pragma abicoder v2;

import {IPoolManager} from "../lib/v4-periphery/lib/v4-core/src/interfaces/IPoolManager.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "../lib/v4-periphery/lib/v4-core/src/types/BalanceDelta.sol";
import {PoolKey} from "../lib/v4-periphery/lib/v4-core/src/types/PoolKey.sol";
import {PoolSwapTest} from "../lib/v4-periphery/lib/v4-core/src/test/PoolSwapTest.sol";
import {IHooks} from "../lib/v4-periphery/lib/v4-core/src/interfaces/IHooks.sol";
import {Constants} from "../lib/v4-periphery/lib/v4-core/test/utils/Constants.sol";
import {Currency, CurrencyLibrary} from "../lib/v4-periphery/lib/v4-core/src/types/Currency.sol";
//import {PoolManager} from "../lib/v4-core/src/PoolManager.sol";
import {TickMath} from "../lib/v4-periphery/lib/v4-core/src/libraries/TickMath.sol";
import "../lib/v3-periphery/contracts/libraries/TransferHelper.sol";
//import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract XucreIndexFunds is Pausable, AccessControl {

    bytes32 public immutable PAUSER_ROLE;
    bytes32 public immutable BATCH_CALL_ROLE;
    // set the router address
    PoolSwapTest swapRouter;
    //PoolManager poolManager;

    address public feeToken;
    uint24 public poolFee;

    // slippage tolerance to allow for unlimited price impact
    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

    struct ETFDefinition {
        address[] targetTokens;
        uint256[] inputAmounts;
        uint24[] poolFees;
        int24[] tickSpacings;
        uint24 sourceFee;
        int24 sourceTickSpacing;
        bool hasFees;
        uint256 amount;
        address sourceToken;
    }

    constructor(
        address owner_xucre,
        //address swapRouter_xucre,
        address tokenContract_xucre,
        address _swapRouter,
        uint24 poolFee_xucre
    ) {
        PAUSER_ROLE = keccak256("PAUSER_ROLE");
        BATCH_CALL_ROLE = keccak256("BATCH_CALL_ROLE");
        _grantRole(DEFAULT_ADMIN_ROLE, owner_xucre);
        _grantRole(PAUSER_ROLE, owner_xucre);
        _grantRole(BATCH_CALL_ROLE, owner_xucre);
        //poolManager = PoolManager(swapRouter_xucre);
        feeToken = tokenContract_xucre;
        poolFee = poolFee_xucre;
        swapRouter = PoolSwapTest(_swapRouter);
    }

    receive() external payable {
        revert("Ether not accepted");
    }

    fallback() external payable {
        revert("Function does not exist");
    }

    function withdrawBalance(
        address xucre_to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (xucre_to != address(0)) {
            address payable ownerPayable = payable(xucre_to);
            ownerPayable.transfer(address(this).balance);
        }
    }

    function withdrawTokenBalance(
        address xucre_to,
        address xucre_tokenAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (xucre_to != address(0)) {
            uint256 balance = checkBalance(xucre_to, xucre_tokenAddress);
            TransferHelper.safeTransfer(xucre_tokenAddress, xucre_to, balance);
        }
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Swap tokens
    /// @param key the pool where the swap is happening
    /// @param amountSpecified the amount of tokens to swap. Negative is an exact-input swap
    /// @param zeroForOne whether the swap is token0 -> token1 or token1 -> token0
    /// @param hookData any data to be passed to the pool's hook
    function swap(PoolKey memory key, int256 amountSpecified, bool zeroForOne, bytes memory hookData) internal returns(BalanceDelta) {
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT // unlimited impact
        });

        // in v4, users have the option to receieve native ERC20s or wrapped ERC6909 tokens
        // here, we'll take the ERC20s
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        
        return swapRouter.swap(key, params, testSettings, hookData);
        //poolManager.swap(key, params, hookData);
    }

    function checkBalance(
        address to_xucre,
        address tokenAddress_xucre
    ) private view returns (uint256) {
        // Create an instance of the token contract
        IERC20 token = IERC20(tokenAddress_xucre);
        // Return the balance of msg.sender
        return token.balanceOf(to_xucre);
    }

    function calculateFromPercent(
        uint256 amount_xucre,
        uint256 bps_xucre
    ) public pure returns (uint256) {
        require((amount_xucre * bps_xucre) >= 10000, "Invalid amount entries");
        return (amount_xucre * bps_xucre) / 10000;
    }

    function performSwapBatch(
        address to_xucre,
        ETFDefinition memory etfDefinition
    ) external whenNotPaused {
        
        // int24[] tickSpacings;
        // uint24 sourceFee;
        // int24 sourceTickSpacing;
        require(
            etfDefinition.targetTokens.length == etfDefinition.inputAmounts.length &&
                etfDefinition.inputAmounts.length == etfDefinition.tickSpacings.length,
            "Invalid input parameters"
        );

        // Sum of input amounts
        uint256 totalInputAmounts = 0;
        for (uint256 i = 0; i < etfDefinition.inputAmounts.length; ++i) {
            totalInputAmounts += etfDefinition.inputAmounts[i];
        }
        require(
            totalInputAmounts == 10000,
            "Input amounts must add up to 10000"
        );

        // Validate wallet balance for source token
        require(checkBalance(to_xucre, etfDefinition.sourceToken) >= etfDefinition.amount, "Insufficient balance");

        // Fee calculation
        uint256 feeTotal = (etfDefinition.amount / 50);
        uint256 totalAfterFees = etfDefinition.hasFees == false ? etfDefinition.amount : etfDefinition.amount - feeTotal;

        // Transfer `totalIn` of USDT to this contract.

        TransferHelper.safeTransferFrom(
            etfDefinition.sourceToken,
            to_xucre,
            address(this),
            etfDefinition.amount
        );
        // Approve the router to spend USDT.
        TransferHelper.safeApprove(
            etfDefinition.sourceToken,
            address(swapRouter),
            etfDefinition.amount
        );

        PoolKey memory feePoolKey = getPoolKey(
            etfDefinition.sourceToken,
            feeToken,
            poolFee,
            etfDefinition.sourceTickSpacing
        );
        if (etfDefinition.hasFees) {
            swap(
                feePoolKey,
                int(calculateFromPercent(totalAfterFees, feeTotal)),
                true,
                new bytes(0)
            );
        }

        for (uint256 i = 0; i < etfDefinition.targetTokens.length; ++i) {
            PoolKey memory poolKey = getPoolKey(
                etfDefinition.sourceToken,
                etfDefinition.targetTokens[i],
                etfDefinition.poolFees[i],
                etfDefinition.tickSpacings[i]
            );
            BalanceDelta balanceDelta = swap(
                poolKey,
                int(calculateFromPercent(totalAfterFees, etfDefinition.inputAmounts[i])),
                true,
                new bytes(0)
            );
            TransferHelper.safeTransferFrom(
                etfDefinition.targetTokens[i],
                address(this),
                to_xucre,                
                uint256(uint128(BalanceDeltaLibrary.amount1(balanceDelta)))
            );
            //require(result, 'Should return a balance');
            
        }

    }

    function getPoolKey(
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) public pure returns (PoolKey memory) {
        return PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: fee,
            hooks: IHooks(Constants.ADDRESS_ZERO),
            tickSpacing: tickSpacing
        });
    }
}
