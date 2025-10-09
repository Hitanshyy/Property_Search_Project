const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();

  const PROPERTY_REGISTRY_ADDRESS = "0xEC69566A6cFA90b5dA2325A413343FC519B7eF6a";

  console.log("Deploying PropertyRental and PropertySearch with account:", deployer.address);
  console.log("Using PropertyRegistry at:", PROPERTY_REGISTRY_ADDRESS);

  // Deploy PropertyRental
  const PropertyRental = await ethers.getContractFactory("PropertyRental");
  const propertyRental = await upgrades.deployProxy(
    PropertyRental,
    [PROPERTY_REGISTRY_ADDRESS],
    { initializer: "initialize" }
  );
  await propertyRental.waitForDeployment();
  console.log("✅ PropertyRental deployed at:", await propertyRental.getAddress());

  // Deploy PropertySearch
  const PropertySearch = await ethers.getContractFactory("PropertySearch");
  const propertySearch = await upgrades.deployProxy(
    PropertySearch,
    [PROPERTY_REGISTRY_ADDRESS],
    { initializer: "initialize" }
  );
  await propertySearch.waitForDeployment();
  console.log("✅ PropertySearch deployed at:", await propertySearch.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });