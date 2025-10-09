const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();

  const PROPERTY_REGISTRY_ADDRESS = "0xEC69566A6cFA90b5dA2325A413343FC519B7eF6a";

  console.log("Deploying FractionalOwnership with account:", deployer.address);
  console.log("Using PropertyRegistry at:", PROPERTY_REGISTRY_ADDRESS);

  const FractionalOwnership = await ethers.getContractFactory("FractionalOwnership");
  const fractionalOwnership = await upgrades.deployProxy(
    FractionalOwnership,
    [PROPERTY_REGISTRY_ADDRESS],
    { initializer: "initialize" }
  );
  await fractionalOwnership.waitForDeployment();
  console.log("✅ FractionalOwnership deployed at:", await fractionalOwnership.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });