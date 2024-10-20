require('@openzeppelin/hardhat-upgrades');
import type { HardhatUserConfig } from "hardhat/types";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
require("dotenv").config();

const networks = {
  hardhat: {
    allowUnlimitedContractSize: true
  },
  polygon: {
    url: 'https://polygon-mainnet.g.alchemy.com/v2/'+process.env.ALCHEMY_API_KEY,
    accounts: [process.env.DEVACCOUNTKEY as string],
    timeout: 600000,
    //gas: 2100000,
    //gasPrice: 8000000000,
  },
  ethereum: {
    url: 'https://eth-mainnet.g.alchemy.com/v2/'+process.env.ALCHEMY_API_KEY,
    accounts: [process.env.DEVACCOUNTKEY as string],
    timeout: 600000,
  },
  base: {
    url: 'https://base-mainnet.g.alchemy.com/v2/'+process.env.ALCHEMY_API_KEY,
    accounts: [process.env.DEVACCOUNTKEY as string],
    timeout: 600000,
  },
  baseSepolia: {
    url: 'https://base-sepolia.g.alchemy.com/v2/'+process.env.ALCHEMY_API_KEY,
    accounts: [process.env.DEVACCOUNTKEY as string],
    timeout: 600000,
  }
}

const config : HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.26",
      },
      {
        version: "0.8.24",
        settings: {},
      },
    ],
    version: "0.8.26",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
      evmVersion: "cancun",
    }
  },
  networks: networks,
  etherscan: {
    apiKey: {
      polygon: process.env.ETHERSCAN_POLYGON_API_KEY as string,
      mainnet: process.env.ETHERSCAN_API_KEY as string,
      base: process.env.ETHERSCAN_BASE_API_KEY as string,
      baseSepolia: process.env.ETHERSCAN_BASE_API_KEY as string
    },
  }
};


export default config;
