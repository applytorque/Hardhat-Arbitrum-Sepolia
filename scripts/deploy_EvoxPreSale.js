// scripts/deploy_EvoxPreSale.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const EvoxPreSale = await ethers.getContractFactory("EvoxPreSale");
  
    // Define start and end time for the presale
    const currentTimeInSeconds = Math.floor(Date.now() / 1000);
    const startTime = currentTimeInSeconds; // current time
    const endTime = currentTimeInSeconds + (10 * 24 * 60 * 60); // 30 days from now
  
    console.log("Start time:", startTime);
    console.log("End time:", endTime);
  
    const evoxPreSale = await EvoxPreSale.deploy(startTime, endTime);
  
    await evoxPreSale.deployed();
  
    console.log("EvoxPreSale deployed to:", evoxPreSale.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  