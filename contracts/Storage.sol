// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { IPropertyRegistry } from "./IOwnership.sol";

/**
 * @title Property Search Storage Contract
 * @dev   This contract holds common variables for the Property Search contract.
*/

contract PropertySearchStorage {

    /**
     * @dev Represents a property listed for sale in the marketplace
     * @param listingId Unique ID for this listing
     * @param propertyId The NFT ID of the property being sold
     * @param seller Address of the property owner listing the property
     * @param price Sale price in wei
     * @param active Whether the listing is currently active
    */
    struct Listing {
        uint256 listingId;
        uint256 propertyId;
        address seller;
        uint256 price;
        bool active;
    }

    // Mapping propertyId → listing
    mapping(uint256 => Listing) internal listings;

    // Ownership history: propertyId => list of previous owners
    mapping(uint256 => address[]) internal ownershipHistory_;

    // Manual listing Ids
    uint256 internal _listingIds;

    // Manual property ID counter
    uint256 internal _propertyIds;

    // Mapping from propertyId to original owner (for history/reference)
    mapping(uint256 => address) internal originalOwner;

    // Reference to PropertyRegistry
    IPropertyRegistry public registry_;

}