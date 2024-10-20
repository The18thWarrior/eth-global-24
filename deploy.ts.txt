
import { ethers, upgrades } from "hardhat";
import '@openzeppelin/hardhat-upgrades';
import PoolManager from './artifacts/lib/v4-core/src/PoolManager.sol/PoolManager.json';
const deploy = false;

const SWAP_ROUTER_ADDRESS = "0x96E3495b712c6589f1D2c50635FDE68CF17AC83c";
const POOL_MANAGER_ADDRESS = "0x7da1d65f8b249183667cde74c5cbd46dd38aa829";
const DEV_ACCOUNT_ADDRESS = process.env.DEVACCOUNTADDRESS;
const OWNER_ADDRESS = process.env.DEVACCOUNTADDRESS as string;

async function main() {
  const signer = await ethers.provider.getSigner(DEV_ACCOUNT_ADDRESS);
  //console.log(signer);
  const signerAddress = await signer.getAddress();
  const poolFee = BigInt(1000);

  const USDC_Factory = await ethers.getContractFactory("USDCoin");
  const USDC = await USDC_Factory.deploy();
  const USDC_transaction = await USDC.deploymentTransaction();
  const USDC_CONTRACT = await USDC.getAddress();
  

  const WBTC_Factory = await ethers.getContractFactory("WrappedBitcoin");
  const WBTC = await WBTC_Factory.deploy();
  const WBTC_transaction = await WBTC.deploymentTransaction();
  const WBTC_CONTRACT = await WBTC.getAddress();


  const WETH_Factory = await ethers.getContractFactory("WrappedETH");
  const WETH = await WETH_Factory.deploy();
  const WETH_transaction = await WETH.deploymentTransaction();
  const WETH_CONTRACT = await WETH.getAddress();


  const AERO_Factory = await ethers.getContractFactory("Aero");
  const AERO = await AERO_Factory.deploy();
  const AERO_transaction = await AERO.deploymentTransaction();
  const AERO_CONTRACT = await AERO.getAddress();

  const MANTRA_Factory = await ethers.getContractFactory("Mantra");
  const MANTRA = await MANTRA_Factory.deploy();
  const MANTRA_transaction = await MANTRA.deploymentTransaction();
  const MANTRA_CONTRACT = await MANTRA.getAddress();

  console.log(`USDC: ${USDC_CONTRACT}`);
  console.log(`WBTC: ${WBTC_CONTRACT}`);
  console.log(`WETH: ${WETH_CONTRACT}`);
  console.log(`AERO: ${AERO_CONTRACT}`);
  console.log(`MANTRA: ${MANTRA_CONTRACT}`);
  
  const poolManager = new ethers.Contract(POOL_MANAGER_ADDRESS, PoolManager.abi, signer);
  //const 
  
  //if (deploy) {
    const Xucre = await ethers.getContractFactory("XucreIndexFunds");
    const xucre = await Xucre.deploy(ethers.getAddress(OWNER_ADDRESS), USDC_CONTRACT, ethers.getAddress(SWAP_ROUTER_ADDRESS),poolFee);
    //await xucre.deployed();
    const transaction = await xucre.deploymentTransaction();
    console.log(transaction);
    console.log("XucreETF deployed to this transaction", transaction?.hash);
    console.log(`verification script: npx hardhat verify --network <network> --contract contracts/XucreIndexFunds.sol:XucreIndexFunds <contractAddress> ${ethers.getAddress(OWNER_ADDRESS)} ${USDC_CONTRACT} ${ethers.getAddress(SWAP_ROUTER_ADDRESS)}  ${poolFee}`);
  
  //}
    
  return;

}


main().catch((error) => {
  console.error(error);
  //console.log('error thrown', error.message)
  process.exitCode = 1;
});

//npx hardhat verify --network baseSepolia --contract contracts/XucreIndexFunds.sol:XucreIndexFunds 0xB0f6e155E4c52998d3586726AB00b25Ec23C4DB0 "0x19316109C70084D0E34C6b28AD5b6298aFB2dB3c" "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913" "0x96E3495b712c6589f1D2c50635FDE68CF17AC83c" 1000