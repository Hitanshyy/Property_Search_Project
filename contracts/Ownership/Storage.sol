// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { IPropertyRegistry } from "../IPropertyRegistry.sol";

/**
 * @title Property Search Storage Contract
 * @dev   This contract holds common variables for the Property Search contract.
*/

contract OwnershipStorage {

    struct Fraction {
        uint256 propertyId;
        uint256 totalShares;        // total shares created for this fraction
        uint256 availableShares;    // shares available for sale
        address owner;              // original owner (seller) of the fraction
        uint256 sharePrice;         // price per share in wei
        mapping(address => uint256) shares; // user -> owned shares
    }

    // Ownership history: propertyId => list of previous owners
    mapping(uint256 => address[]) internal ownershipHistory_;

    // Manual property ID counter (reserved for future use)
    uint256 internal _propertyIds;

    // Mapping from propertyId to original owner (for history/reference)
    mapping(uint256 => address) internal originalOwner;

    // Fraction state
    uint256 public fractionCount;
    mapping(uint256 => Fraction) internal fractions; // fractionId => Fraction

    // Mapping from propertyId to fractionId (to avoid duplicate fractionalization)
    mapping(uint256 => uint256) public propertyToFractionId;

    // Reference to PropertyRegistry
    IPropertyRegistry public registry_;
    
}