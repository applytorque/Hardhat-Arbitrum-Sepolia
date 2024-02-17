// deploy.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // We get the contract to deploy
  const MyToken = await ethers.getContractFactory("AdvancedAntiSnipeBotToken");
  const myToken = await MyToken.deploy({
    gasPrice: ethers.utils.parseUnits('20', 'gwei') // Adjust the gas price as needed
  });

  console.log("myToken deployed to:", myToken.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
