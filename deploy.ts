
import { ethers, upgrades } from "hardhat";
import '@openzeppelin/hardhat-upgrades';
const deploy = false;

const SWAP_ROUTER_ADDRESS = "0x96E3495b712c6589f1D2c50635FDE68CF17AC83c";
const DEV_ACCOUNT_ADDRESS = process.env.DEVACCOUNTADDRESS;
const OWNER_ADDRESS = process.env.DEVACCOUNTADDRESS as string;

async function main() {
  const signer = await ethers.provider.getSigner(DEV_ACCOUNT_ADDRESS);
  //console.log(signer);
  const signerAddress = await signer.getAddress();
  const poolFee = BigInt(1000);
  console.log(signerAddress)

  const USDC_CONTRACT = ethers.getAddress('0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913');
  
  //if (deploy) {
    const Xucre = await ethers.getContractFactory("XucreIndexFunds");
    const xucre = await Xucre.deploy(ethers.getAddress(OWNER_ADDRESS), USDC_CONTRACT, ethers.getAddress(SWAP_ROUTER_ADDRESS),poolFee);
    //await xucre.deployed();
    const transaction = await xucre.deploymentTransaction();
    console.log(transaction);
    console.log("XucreETF deployed to this transaction", transaction?.hash);
    console.log(`verification script: npx hardhat verify --network <network> --contract contracts/XucreETF.sol:XucreETF <contractAddress> ${ethers.getAddress(OWNER_ADDRESS)} ${ethers.getAddress(SWAP_ROUTER_ADDRESS)} ${USDC_CONTRACT} ${poolFee}`);
  
  //}
    
  return;

}


main().catch((error) => {
  console.error(error);
  //console.log('error thrown', error.message)
  process.exitCode = 1;
});