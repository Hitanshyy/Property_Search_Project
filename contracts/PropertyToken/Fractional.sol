// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { PropertyTokenStorage } from "./Storage.sol";
import { AccessModifiers } from "./AccessModifiers.sol";

contract Fractions is AccessModifiers, ReentrancyGuardUpgradeable {

    PropertyTokenStorage internal storage_;

    event FractionPurchased(
        address indexed buyer, 
        uint256 indexed propertyId, 
        uint256 amount, 
        uint256 price
    );

    event FractionSold(
        address indexed seller, 
        uint256 indexed propertyId, 
        uint256 amount, 
        uint256 price
    );

    mapping(uint256 => mapping(address => uint256)) public fractionBalances;
    mapping(uint256 => address[]) public propertyInvestors;

    function initialize(address _roleManager) public initializer {
        __ReentrancyGuard_init();
        require(_roleManager != address(0), "Invalid roleManager");
        roleManager = _roleManager;
    }

    function buyFraction(uint256 propertyId, uint256 amount) external payable nonReentrant onlyKYCVerified(msg.sender) {
        PropertyTokenStorage.PropertyInfo memory prop = PropertyTokenStorage(storage_).getProperty(propertyId);
        require(prop.tradingEnabled, "Trading disabled");

        uint256 fractionPrice = prop.propertyValue / prop.totalFractions;
        require(msg.value >= amount * fractionPrice, "Insufficient payment");

        fractionBalances[propertyId][msg.sender] += amount;
        propertyInvestors[propertyId].push(msg.sender);

        emit FractionPurchased(msg.sender, propertyId, amount, msg.value);
    }

    function sellFraction(uint256 propertyId, uint256 amount) external nonReentrant onlyKYCVerified(msg.sender) {
        require(fractionBalances[propertyId][msg.sender] >= amount, "Insufficient balance");

        PropertyTokenStorage.PropertyInfo memory prop = PropertyTokenStorage(storage_).getProperty(propertyId);

        uint256 fractionPrice = prop.propertyValue / prop.totalFractions;
        uint256 payout = amount * fractionPrice;

        fractionBalances[propertyId][msg.sender] -= amount;
        payable(msg.sender).transfer(payout);

        emit FractionSold(msg.sender, propertyId, amount, payout);
    }
}

