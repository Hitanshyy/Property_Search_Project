// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { IPropertyRegistry } from "../IPropertyRegistry.sol";

/**
 * @title Property Search Storage Contract
 * @dev   This contract holds common variables for the Property Search contract.
*/

contract PropertyStorage {

    struct Property {
        uint256 id;
        address owner;
        string location;
        uint256 price;
        string propertyType;
        uint256 size;
        bool listed;
    }

    struct Rental {
        uint256 propertyId;
        address renter;
        uint256 rentAmount;
        uint256 startTime;
        uint256 duration;
        bool active;
    }

    // Ownership history: propertyId => list of previous owners
    mapping(uint256 => address[]) internal ownershipHistory_;

    // Manual property ID counter
    uint256 internal _propertyIds;

    // Mapping from propertyId to original owner (for history/reference)
    mapping(uint256 => address) internal originalOwner;

    uint256 public propertyCount;

    mapping(uint256 => Property) internal properties;

    mapping(address => uint256[]) internal ownerProperties;

    uint256 public rentalCount;

    mapping(uint256 => Rental) public rentals; // rentalId => Rental

    mapping(uint256 => uint256) public propertyToRental; // propertyId => rentalId

    // Reference to PropertyRegistry
    IPropertyRegistry public registry_;

}