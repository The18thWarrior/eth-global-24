
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
pragma abicoder v2;

import {IPoolManager} from "../lib/v4-core/src/interfaces/IPoolManager.sol";
import {BalanceDelta} from "../lib/v4-core/src/types/BalanceDelta.sol";
import {PoolKey} from "../lib/v4-core/src/types/PoolKey.sol";
import {PoolSwapTest} from "../lib/v4-core/src/test/PoolSwapTest.sol";
import {PoolManager} from "../lib/v4-core/src/PoolManager.sol";
import {TickMath} from "../lib/v4-core/src/libraries/TickMath.sol";
import "../lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Swap is Pausable, AccessControl {

    bytes32 public immutable PAUSER_ROLE;
    bytes32 public immutable BATCH_CALL_ROLE;
    // set the router address
    PoolSwapTest swapRouter;
    PoolManager poolManager;

    address public feeToken;
    uint24 public poolFee;

    // slippage tolerance to allow for unlimited price impact
    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

    struct ETFDefinition {
        address[] targetTokens;
        uint256[] inputAmounts;
        uint24[] poolFees;
        PoolKey[] poolKeys;
        PoolKey feeKey;
        bool hasFees;
        uint256 amount;
        address sourceToken;
    }

    constructor(
        address owner_xucre,
        address swapRouter_xucre,
        address tokenContract_xucre,
        address _swapRouter,
        uint24 poolFee_xucre
    ) {
        PAUSER_ROLE = keccak256("PAUSER_ROLE");
        BATCH_CALL_ROLE = keccak256("BATCH_CALL_ROLE");
        _grantRole(DEFAULT_ADMIN_ROLE, owner_xucre);
        _grantRole(PAUSER_ROLE, owner_xucre);
        _grantRole(BATCH_CALL_ROLE, owner_xucre);
        //0xc81462fec8b23319f288047f8a03a57682a35c1a
        poolManager = PoolManager(swapRouter_xucre);
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
    function swap(PoolKey memory key, int256 amountSpecified, bool zeroForOne, bytes memory hookData) internal {
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT // unlimited impact
        });

        // in v4, users have the option to receieve native ERC20s or wrapped ERC6909 tokens
        // here, we'll take the ERC20s
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        
        swapRouter.swap(key, params, testSettings, hookData);
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
        require(
            etfDefinition.targetTokens.length == etfDefinition.inputAmounts.length &&
                etfDefinition.inputAmounts.length == etfDefinition.poolKeys.length,
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
            address(poolManager),
            etfDefinition.amount
        );

        if (etfDefinition.hasFees) {
            swap(
                etfDefinition.feeKey,
                int(calculateFromPercent(totalAfterFees, feeTotal)),
                true,
                new bytes(0)
            );
            // ISwapRouter.ExactInputParams memory feeParams = ISwapRouter
            //     .ExactInputParams({
            //         path: abi.encodePacked(sourceToken, poolFee, feeToken),
            //         recipient: address(this),
            //         deadline: block.timestamp,
            //         amountIn: feeTotal,
            //         amountOutMinimum: 1
            //     });
            

            // Executes the fee swap.
            // xucre_swapRouter.exactInput(feeParams);
        }

        for (uint256 i = 0; i < etfDefinition.targetTokens.length; ++i) {
            swap(
                etfDefinition.poolKeys[i],
                int(calculateFromPercent(totalAfterFees, etfDefinition.inputAmounts[i])),
                true,
                new bytes(0)
            );
            TransferHelper.safeTransferFrom(
                etfDefinition.targetTokens[i],
                address(this),
                to_xucre,                
                etfDefinition.amount
            );
            //require(result, 'Should return a balance');
            
        }

        /*uint256[2] memory resultingTotals;
        resultingTotals = [_totalIn, totalIn];
        return resultingTotals;*/
    }


}


// contract FlashLoanLP {
//   IPoolManager public poolManager;
//   address public tokenA;
//   address public tokenB;

//   constructor(address _poolManager, address _tokenA, address _tokenB) {
//     poolManager = IPoolManager(_poolManager);
//     tokenA = _tokenA;
//     tokenB = _tokenB;
//   }

//   function executeFlashLoan(uint256 amountA, uint256 amountB) external {
//     // Request flash loan
//     poolManager.flashLoan(address(this), tokenA, amountA, msg.sender);
//     poolManager.flashLoan(address(this), tokenB, amountB, "");
//   }

//   function onFlashLoan(
//     address initiator,
//     address token,
//     uint256 amount,
//     uint256 fee,
//     bytes calldata data
//   ) external returns (bytes32) {
//     require(msg.sender == address(poolManager), "Unauthorized");

//     // Approve tokens to pool manager
//     IERC20(token).approve(address(poolManager), amount);

//     // Add liquidity to the pool
//     poolManager.addLiquidity(tokenA, tokenB, amount, amount, 0, 0, address(this), block.timestamp);

//     // Repay the flash loan
//     IERC20(token).transfer(address(poolManager), amount + fee);

//     return keccak256("FlashLoanLP.onFlashLoan");
//   }
// }
