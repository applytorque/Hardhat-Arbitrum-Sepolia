const { ethers, upgrades } = require("hardhat");

async function main() {
  const EQXToken = await ethers.getContractFactory("MetaVault");
  const proxy = await upgrades.deployProxy(
    EQXToken,
    ["METAVAULT", "MV", 18, 0, 100000000, 10000000],
    { gasLimit: "90000000" }
  );
  await proxy.deployed();

  console.log(proxy.address);
  console.log("Metavault contract:", proxy.address);
  await hre.run("verify:verify", {
    address: proxy.address,
    constructorArguments: [],
  });
}

main();
