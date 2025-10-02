const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with account:", deployer.address);

  // Get the PropertyRegistry contract factory
  const PropertyRegistry = await ethers.getContractFactory("PropertyRegistry");

  // Deploy upgradeable proxy with deployer as admin
  const registry = await upgrades.deployProxy(PropertyRegistry, [deployer.address], {
    initializer: "initialize",
  });

  await registry.waitForDeployment();

  console.log("✅ PropertyRegistry deployed at:", await registry.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
