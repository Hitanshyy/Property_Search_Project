const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();

  // deployed PropertyRegistry address
  const PROPERTY_REGISTRY_ADDRESS = "0xEC69566A6cFA90b5dA2325A413343FC519B7eF6a";

  console.log("Deploying Ownership contract with account:", deployer.address);
  console.log("Using PropertyRegistry at:", PROPERTY_REGISTRY_ADDRESS);

  // Get the contract factory
  const Ownership = await ethers.getContractFactory("Ownership");

  // Deploy upgradeable proxy, passing registry address and deployer as admin
  const ownership = await upgrades.deployProxy(
    Ownership,
    [PROPERTY_REGISTRY_ADDRESS, deployer.address],
    { initializer: "initialize" }
  );

  await ownership.waitForDeployment();

  console.log("✅ Ownership contract deployed at:", await ownership.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
