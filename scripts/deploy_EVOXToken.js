
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const EVOXToken = await ethers.getContractFactory("EVOXToken");
  const evoxToken = await EVOXToken.deploy();

  console.log("EVOXToken deployed to:", evoxToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
