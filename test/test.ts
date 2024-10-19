import { ethers, upgrades } from "hardhat";
import { ERC20__factory } from "../typechain-types";
import '@openzeppelin/hardhat-upgrades';
import { JsonRpcSigner, JsonRpcProvider } from "@ethersproject/providers";
import { BigNumber } from "ethers";


const deploy = false;

const SWAP_ROUTER_ADDRESS = "0x0";
const DEV_ACCOUNT_ADDRESS = process.env.DEVACCOUNTADDRESS;
const OWNER_ADDRESS = process.env.DEVACCOUNTADDRESS as string;
const DAI = "0x0";
const USDT = "0x0";
const WBTC = "0x0";
const UNI = async (signer: JsonRpcSigner) => {
  return await ERC20__factory.connect("0x0", signer);
}
const XUCRE = async (signer: JsonRpcSigner) => {
  return await ERC20__factory.connect("0x0", signer);
}

async function test() {
  //const prov = String('https://rpc.buildbear.io/vicious-goose-bfec7fbe');
  //console.log(prov);
  //const signer = new JsonRpcProvider(prov).getSigner();
  const signer = ethers.provider.getSigner(DEV_ACCOUNT_ADDRESS);
  //console.log(signer);
  const signerAddress = await signer.getAddress();
  const poolFee = BigNumber.from(10000);
  console.log(signerAddress)

  const USDT_CONTRACT = await ERC20__factory.connect(USDT, signer);
  const XUCRE_CONTRACT = await XUCRE(signer);
  const UNI_CONTRACT = await UNI(signer);
  //console.log('1');
  const balance = await DAI_CONTRACT.balanceOf(signerAddress);
  console.log('initial DAI balance', balance.toString());
  const wbtcbalance = await WBTC_CONTRACT.balanceOf(signerAddress);
  console.log('initial WBTC balance', wbtcbalance.toString());
  const unibalance = await UNI_CONTRACT.balanceOf(signerAddress);
  console.log('initial UNI balance', unibalance.toString());

  const balanceUSDT = await USDT_CONTRACT.balanceOf(signerAddress);
  console.log('usdt initial balance', balanceUSDT.toString());

  if (!deploy) {
    const sendsome = await USDT_CONTRACT.transfer('0x0', balanceUSDT.div(100));
    const balanceUSDT2 = await USDT_CONTRACT.balanceOf('0x0');
    console.log('usdt brave balance', balanceUSDT2.toString());
  }
  
  if (deploy) {
    const Xucre = await ethers.getContractFactory("XucreETF");
    const xucre = await Xucre.deploy(ethers.utils.getAddress(OWNER_ADDRESS), ethers.utils.getAddress(SWAP_ROUTER_ADDRESS), XUCRE_CONTRACT.address,poolFee);
    await xucre.deployed();
    console.log("XucreETF deployed to:", xucre.address);
    
    const result = await USDT_CONTRACT.approve(xucre.address, ethers.utils.parseEther('100'));

    console.log('approved', result.hash);
    try {
      const runSwap = await xucre.spotExecution(signerAddress, [ethers.utils.getAddress(DAI), ethers.utils.getAddress(WBTC), UNI_CONTRACT.address], [6000, 2000, 2000], [3000, 3000, 3000], USDT_CONTRACT.address, balanceUSDT.div(100));
      const res2 = await runSwap.wait();
      //const events = res2["events"] as unknown as Event[];
      //console.log(JSON.stringify(events, null, 2))
    } catch (err) {
      console.log('error thrown');
    }

    const final_balance = await DAI_CONTRACT.balanceOf(signerAddress);
    console.log('final DAI balance', final_balance.toString());

    const final_wbtcbalance = await WBTC_CONTRACT.balanceOf(signerAddress);
    console.log('final WBTC balance', final_wbtcbalance.toString());

    const final_unibalance = await UNI_CONTRACT.balanceOf(signerAddress);
    console.log('final UNI balance', final_unibalance.toString());
  
  }
    
  return;
  //const name = await xucre.name();
  //console.log('token name', name);

}