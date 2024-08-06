// scripts/check_balance.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    const proxyAddress = "0x811690A9c5B4239a33C4a66076a40d3e6ABD4750";
    const EVOXToken = await ethers.getContractAt("EVOXToken", proxyAddress);
    
    const balance = await EVOXToken.balanceOf(deployer.address);
    console.log("Balance of deployer:", ethers.utils.formatUnits(balance, 10));
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  