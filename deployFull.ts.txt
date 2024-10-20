import { ethers } from "hardhat";
import '@openzeppelin/hardhat-upgrades';

import { PoolKey, Currency } from "./types/PoolKey"; // Define PoolKey and Currency types based on your implementation

// Configuration variables
const lpFee = 3000; // Example: 0.30% liquidity provider fee
const tickSpacing = 60;
const startingPrice = BigInt("79228162514264337593543950336"); // sqrtPriceX96 for initial price
const token0Amount = ethers.parseUnits("100", 18); // Adjust decimals based on token
const token1Amount = ethers.parseUnits("1", 8); // Adjust decimals based on token

// Tick range for liquidity
const tickLower = -600;
const tickUpper = 600;

// Hooks placeholder
const hookContract = ethers.ZeroAddress; // Set to actual hook contract if needed

async function createPair(
  currency0: string,
  currency1: string,
  posmAddress: string,
  signer: any
) {
  // Get contract instances
  const PositionManager = await ethers.getContractFactory("PositionManager");
  const posm = await PositionManager.attach(posmAddress).connect(signer);

  // Define PoolKey
  const pool: PoolKey = {
    currency0: currency0,
    currency1: currency1,
    fee: lpFee,
    tickSpacing: tickSpacing,
    hooks: hookContract,
  };

  // Convert token amounts to liquidity units
  const LiquidityAmounts = await ethers.getContractFactory("LiquidityAmounts");
  const liquidity = await LiquidityAmounts.getLiquidityForAmounts(
    startingPrice,
    TickMath.getSqrtPriceAtTick(tickLower),
    TickMath.getSqrtPriceAtTick(tickUpper),
    token0Amount,
    token1Amount
  );

  // Slippage limits
  const amount0Max = token0Amount.add(1); // Add 1 wei to max amount
  const amount1Max = token1Amount.add(1);

  // Generate mint parameters
  const [actions, mintParams] = await _mintLiquidityParams(
    pool,
    tickLower,
    tickUpper,
    liquidity,
    amount0Max,
    amount1Max,
    signer.address,
    "0x"
  );

  // Multicall parameters
  const params = [
    posm.interface.encodeFunctionData("initializePool", [
      pool,
      startingPrice,
      "0x", // Empty hook data
    ]),
    posm.interface.encodeFunctionData("modifyLiquidities", [
      actions,
      mintParams,
      Math.floor(Date.now() / 1000) + 60, // Set a deadline 60 seconds from now
    ]),
  ];

  // If currency0 is ETH, set value to amount0Max
  const valueToPass = currency0 === ethers.ZeroAddress ? amount0Max : 0;

  // Approve tokens for the transaction
  await tokenApprovals(currency0, currency1, amount0Max, amount1Max, signer);

  // Execute multicall to create pool and add liquidity atomically
  const tx = await posm.multicall(params, { value: valueToPass });
  await tx.wait();

  console.log("Pair created and liquidity added successfully");
}

// Helper function to approve tokens
async function tokenApprovals(
  token0: string,
  token1: string,
  amount0Max: BigNumber,
  amount1Max: BigNumber,
  signer: any
) {
  const ERC20 = await ethers.getContractFactory("ERC20");

  // Approve token0
  if (token0 !== ethers.AddressZero) {
    const token0Contract = ERC20.attach(token0).connect(signer);
    await token0Contract.approve(signer.address, amount0Max);
  }

  // Approve token1
  if (token1 !== ethers.constants.AddressZero) {
    const token1Contract = ERC20.attach(token1).connect(signer);
    await token1Contract.approve(signer.address, amount1Max);
  }
}

// Helper function to generate mint liquidity parameters
async function _mintLiquidityParams(
  pool: PoolKey,
  tickLower: number,
  tickUpper: number,
  liquidity: BigNumber,
  amount0Max: BigNumber,
  amount1Max: BigNumber,
  recipient: string,
  hookData: string
): Promise<[string, string[]]> {
  // Logic for generating mint actions and parameters based on Uniswap v4 structure
  // This will depend on your actual PositionManager contract interface

  // Placeholder for demonstration
  const actions = "0x"; // Replace with actual action encoding logic
  const mintParams = ["0x"]; // Replace with actual mint parameters

  return [actions, mintParams];
}


async function main() {
  // Get signer information
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Load environment variables
  const OWNER_ADDRESS: string = process.env.DEVACCOUNTADDRESS || "";
  const POOL_MANAGER_ADDRESS: string = process.env.POOL_MANAGER_ADDRESS || "";
  const SWAP_ROUTER_ADDRESS: string = process.env.SWAP_ROUTER_ADDRESS || "";

  // Constants
  const POOL_FEE: number = 1000;

  // Deploy tokens
  const USDCoinFactory = await ethers.getContractFactory("USDCoin");
  const usdc = await USDCoinFactory.deploy();
  await usdc.deploymentTransaction();
  const usdcContract =await usdc.getAddress();
  console.log(`USDC deployed at: ${usdcContract}`);

  const WrappedBitcoinFactory = await ethers.getContractFactory("WrappedBitcoin");
  const wbtc = await WrappedBitcoinFactory.deploy();
  await wbtc.deploymentTransaction();
  const wbtcContract =await wbtc.getAddress();
  console.log(`WBTC deployed at: ${wbtcContract}`);

  const WrappedETHFactory = await ethers.getContractFactory("WrappedETH");
  const weth = await WrappedETHFactory.deploy();
  await weth.deploymentTransaction();
  const wethContract =await weth.getAddress();
  console.log(`WETH deployed at: ${wethContract}`);

  const AeroFactory = await ethers.getContractFactory("Aero");
  const aero = await AeroFactory.deploy();
  await aero.deploymentTransaction();
  const aeroContract =await aero.getAddress();
  console.log(`AERO deployed at: ${aeroContract}`);

  const MantraFactory = await ethers.getContractFactory("Mantra");
  const mantra = await MantraFactory.deploy();
  await mantra.deploymentTransaction();
  const mantraContract =await mantra.getAddress();
  console.log(`MANTRA deployed at: ${mantraContract}`);

  const SolanaFactory = await ethers.getContractFactory("Solana");
  const solana = await SolanaFactory.deploy();
  await solana.deploymentTransaction();
  const solanaContract =await solana.getAddress();
  console.log(`SOL deployed at: ${solanaContract}`);

  const PolygonFactory = await ethers.getContractFactory("Polygon");
  const polygon = await PolygonFactory.deploy();
  await polygon.deploymentTransaction();
  const polygonContract =await polygon.getAddress();
  console.log(`POL deployed at: ${polygonContract}`);

  // Interact with the PoolManager
  const PoolManagerFactory = await ethers.getContractFactory("PoolManager");
  const poolManager = await PoolManagerFactory.attach(POOL_MANAGER_ADDRESS);

  // Create pairs
  await createPair(usdcContract, wbtcContract);
  await createPair(usdcContract, wethContract);
  await createPair(usdcContract, aeroContract);
  await createPair(usdcContract, mantraContract);
  await createPair(usdcContract, solanaContract);
  await createPair(usdcContract, polygonContract);

  // Deploy XucreIndexFunds contract
  const XucreFactory = await ethers.getContractFactory("XucreIndexFunds");
  const xucre = await XucreFactory.deploy(
    OWNER_ADDRESS,
    usdcContract,
    SWAP_ROUTER_ADDRESS,
    POOL_FEE
  );
  await xucre.deployed();
  const xucreContract = xucre.address;
  console.log(`XucreIndexFunds deployed at: ${xucreContract}`);

  // Output verification script
  console.log(
    `Verification command: npx hardhat verify --network <network> ${xucreContract} ` +
    `${OWNER_ADDRESS} ${usdcContract} ${SWAP_ROUTER_ADDRESS} ${POOL_FEE}`
  );
}

// Run the script
main().catch((error) => {
  console.error("Error:", error);
  process.exitCode = 1;
});
