const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();

  // ✅ Fill in deployed addresses
  const PROPERTY_REGISTRY_ADDRESS = "0xEC69566A6cFA90b5dA2325A413343FC519B7eF6a";
  const OWNERSHIP_ADDRESS = "0xYOUR_OWNERSHIP_ADDRESS";

  console.log("Deploying Marketplace contracts with account:", deployer.address);
  console.log("PropertyRegistry:", PROPERTY_REGISTRY_ADDRESS);
  console.log("Ownership:", OWNERSHIP_ADDRESS);

  // Deploy Bidding
  const Bidding = await ethers.getContractFactory("Bidding");
  const bidding = await upgrades.deployProxy(
    Bidding,
    [PROPERTY_REGISTRY_ADDRESS, OWNERSHIP_ADDRESS],
    { initializer: "initialize" }
  );
  await bidding.waitForDeployment();
  console.log("✅ Bidding deployed at:", await bidding.getAddress());

  // Deploy Marketplace
  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await upgrades.deployProxy(
    Marketplace,
    [PROPERTY_REGISTRY_ADDRESS, deployer.address, OWNERSHIP_ADDRESS],
    { initializer: "initialize" }
  );
  await marketplace.waitForDeployment();
  console.log("✅ Marketplace deployed at:", await marketplace.getAddress());

  // Deploy Offers
  const Offers = await ethers.getContractFactory("Offers");
  const offers = await upgrades.deployProxy(
    Offers,
    [PROPERTY_REGISTRY_ADDRESS, OWNERSHIP_ADDRESS],
    { initializer: "initialize" }
  );
  await offers.waitForDeployment();
  console.log("✅ Offers deployed at:", await offers.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });