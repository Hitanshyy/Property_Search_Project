// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { IPropertyRegistry } from "../IOwnership.sol";

/**
 * @title Property Search Storage Contract
 * @dev   This contract holds common variables for the Property Search contract.
*/

contract MarketPlaceStorage {

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

    /**
     * @dev Stores data for property offers.
     * @param buyer Address of the buyer making the offer
     * @param amount Amount of ether (wei) offered by the buyer
     * @param active Whether the offer is currently active
    */
    struct Offer {
        address buyer;
        uint256 amount;
        bool active;
    }

    /**
     * @dev Stores auction details for a property.
     * @param seller Address of the property owner who started the auction
     * @param startPrice Minimum starting bid price for the auction (in wei)
     * @param highestBid Current highest bid placed on the property (in wei)
     * @param highestBidder Address of the user who placed the highest bid
     * @param endTime Timestamp indicating when the auction ends
     * @param active Whether the auction is currently active
    */
    struct Auction {
        address seller;
        uint256 startPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool active;
    }
    
    // Mapping propertyId → listing
    mapping(uint256 => Listing) internal listings;

    // Manual listing Ids
    uint256 internal _listingIds;

    // propertyId => list of offers
    mapping(uint256 => Offer[]) internal offers;

    // propertyId => best (highest) offer index
    mapping(uint256 => uint256) internal bestOfferIndex;

    mapping(uint256 => Auction) internal auctions;

    // Reference to PropertyRegistry
    IPropertyRegistry public registry_;

}