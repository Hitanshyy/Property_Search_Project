// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PropertySearchStorage } from "./Storage.sol";
import { IPropertyRegistry } from "./IOwnership.sol";

/**
 * @title Marketplace Contract
 * @notice Enables property owners to list and sell property NFTs.
 */
contract Marketplace is Initializable, AccessControlUpgradeable, PropertySearchStorage {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    /**
     * @dev Emitted when a property is listed for sale
     * @param listingId Unique ID of the listing
     * @param propertyId NFT ID of the property
     * @param seller Address of the property owner
     * @param price Sale price in wei
    */
    event PropertyListed(
        uint256 indexed listingId,
        uint256 indexed propertyId,
        address indexed seller,
        uint256 price
    );

    /**
     * @dev Emitted when a property listing is removed by the seller
     * @param propertyId NFT ID of the property
     * @param seller Address of the property owner who delisted
    */
    event PropertyDelisted(
        uint256 indexed propertyId, 
        address indexed seller
    );

    /**
     * @dev Emitted when a property is purchased
     * @param listingId Unique ID of the listing
     * @param propertyId NFT ID of the property
     * @param buyer Address of the buyer
     * @param price Sale price in wei
    */
    event PropertyPurchased(
        uint256 indexed listingId,
        uint256 indexed propertyId,
        address indexed buyer,
        uint256 price
    );

    /**
     * @notice Initializes the Marketplace contract
     * @param registryAddress Address of the PropertyRegistry contract
     * @param admin Address of the admin
    */
    function initialize(address registryAddress, address admin) public initializer {
        require(registryAddress != address(0), "Invalid registry address");
        require(admin != address(0), "Invalid admin address");

        __AccessControl_init();

        registry_ = IPropertyRegistry(registryAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    /**
     * @notice List a property NFT for sale
     * @param propertyId ID of the property NFT
     * @param price Sale price in wei
    */
    function listProperty(uint256 propertyId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        address owner = registry_.ownerOf(propertyId);
        require(owner == msg.sender, "Caller is not property owner");

        _listingIds += 1;
        listings[propertyId] = Listing({
            listingId: _listingIds,
            propertyId: propertyId,
            seller: msg.sender,
            price: price,
            active: true
        });

        emit PropertyListed(_listingIds, propertyId, msg.sender, price);
    }

    /**
     * @notice Delist an active property
     * @param propertyId ID of the property NFT
    */
    function delistProperty(uint256 propertyId) external {
        Listing storage listing = listings[propertyId];
        require(listing.active, "Property not listed");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;
        emit PropertyDelisted(propertyId, msg.sender);
    }

    /**
     * @notice Purchase a listed property (direct sale)
     * @param propertyId ID of the property NFT to buy
    */
    function buyProperty(uint256 propertyId) external payable {
        Listing storage listing = listings[propertyId];
        require(listing.active, "Property not listed");
        require(msg.sender != listing.seller, "Seller cannot buy own property");
        require(msg.value == listing.price, "Incorrect payment amount");

        listing.active = false;

        // Transfer payment to seller
        payable(listing.seller).transfer(msg.value);

        // Transfer property ownership
        registry_.safeTransferFrom(listing.seller, msg.sender, propertyId);

        emit PropertyPurchased(listing.listingId, propertyId, msg.sender, listing.price);
    }

    /**
     * @notice Get details of a property listing
     * @param propertyId Property NFT ID
     * @return Listing details
    */
    function getListing(uint256 propertyId) external view returns (Listing memory) {
        return listings[propertyId];
    }
}