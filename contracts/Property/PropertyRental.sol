// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { PropertyStorage } from "./Storage.sol";
import { IPropertyRegistry } from "../IPropertyRegistry.sol";

/**
 * @title Property Rental Contract
 * @notice Allows property owners to list rentals and renters to pay rent.
 */
contract PropertyRental is Initializable, ReentrancyGuardUpgradeable, PropertyStorage {

    event RentalListed(
        uint256 indexed propertyId, 
        uint256 rentAmount, 
        uint256 duration
    );

    event PropertyRented(
        uint256 indexed propertyId, 
        address indexed renter, 
        uint256 startTime
    );

    event RentalEnded(
        uint256 indexed propertyId, 
        address indexed renter
    );

    function initialize(address registryAddress) public initializer {
        __ReentrancyGuard_init();
        require(registryAddress != address(0), "Invalid registry");
        registry_ = IPropertyRegistry(registryAddress);
    }

    function listForRent(uint256 propertyId, uint256 rentAmount, uint256 duration) external {
        address owner = registry_.ownerOf(propertyId);
        require(owner == msg.sender, "Not property owner");
        require(duration > 0 && rentAmount > 0, "Invalid rental details");

        rentalCount++;
        rentals[rentalCount] = Rental({
            propertyId: propertyId,
            renter: address(0),
            rentAmount: rentAmount,
            startTime: 0,
            duration: duration,
            active: false
        });
        propertyToRental[propertyId] = rentalCount;

        emit RentalListed(propertyId, rentAmount, duration);
    }

    function rentProperty(uint256 propertyId) external payable nonReentrant {
        uint256 rentalId = propertyToRental[propertyId];
        Rental storage rental = rentals[rentalId];

        require(msg.value == rental.rentAmount, "Incorrect rent");
        require(!rental.active, "Already rented");

        rental.renter = msg.sender;
        rental.startTime = block.timestamp;
        rental.active = true;

        emit PropertyRented(propertyId, msg.sender, block.timestamp);
    }

    function endRental(uint256 propertyId) external nonReentrant {
        uint256 rentalId = propertyToRental[propertyId];
        Rental storage rental = rentals[rentalId];

        require(msg.sender == rental.renter, "Not renter");
        require(block.timestamp >= rental.startTime + rental.duration, "Rental not finished");

        rental.active = false;
        payable(registry_.ownerOf(propertyId)).transfer(rental.rentAmount);

        emit RentalEnded(propertyId, msg.sender);
    }
}