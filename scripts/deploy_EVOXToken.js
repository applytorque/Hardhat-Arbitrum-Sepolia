import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const EVOXToken = await ethers.getContractFactory("EVOXToken");
  
  const evoxToken = await upgrades.deployProxy(EVOXToken, [], { 
    initializer: 'initialize',
    kind: 'uups'
  });

  await evoxToken.waitForDeployment();
  console.log("EVOXToken deployed to:", await evoxToken.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });