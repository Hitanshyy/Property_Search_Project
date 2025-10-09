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
        uint256 totalShares;
        mapping(address => uint256) shares;
    }

    // Ownership history: propertyId => list of previous owners
    mapping(uint256 => address[]) internal ownershipHistory_;

    // Manual property ID counter
    uint256 internal _propertyIds;

    // Mapping from propertyId to original owner (for history/reference)
    mapping(uint256 => address) internal originalOwner;

    uint256 public fractionCount;
    
    mapping(uint256 => Fraction) public fractions; // fractionId => Fraction

    // Reference to PropertyRegistry
    IPropertyRegistry public registry_;

}