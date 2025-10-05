// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { IPropertyRegistry } from "./IOwnership.sol";

/**
 * @title Property Search Storage Contract
 * @dev   This contract holds common variables for the Property Search contract.
*/

contract PropertySearchStorage {

    // Ownership history: propertyId => list of previous owners
    mapping(uint256 => address[]) internal ownershipHistory_;

    // Manual property ID counter
    uint256 internal _propertyIds;

    // Mapping from propertyId to original owner (for history/reference)
    mapping(uint256 => address) internal originalOwner;

    // Reference to PropertyRegistry
    IPropertyRegistry public registry_;

}