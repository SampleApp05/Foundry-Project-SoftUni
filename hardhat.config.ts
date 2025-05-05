import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
// import "@nomicfoundation/hardhat-foundry";
import * as dotenv from "dotenv";

// require("hardhat-foundry");

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      evmVersion: "cancun",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: "./src", // Contracts location
    tests: "./hardhat-tests", // Hardhat tests
    artifacts: "./artifacts",
    cache: "./cache",
  },
  defaultNetwork: "localhost",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: process.env.WALLET_PRIVATE_KEY
        ? [`0x${process.env.WALLET_PRIVATE_KEY}`]
        : [],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || "",
  },
  sourcify: {
    enabled: true,
  },
};

export default config;
