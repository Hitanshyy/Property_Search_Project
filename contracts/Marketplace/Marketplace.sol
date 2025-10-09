// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { MarketPlaceStorage } from "./Storage.sol";
import { IPropertyRegistry } from "../IPropertyRegistry.sol";

/**
 * @title Marketplace Contract
 * @notice Enables property owners to list and sell property NFTs.
 */
contract Marketplace is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, MarketPlaceStorage {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    event PropertyListed(
        uint256 indexed listingId,
        uint256 indexed propertyId,
        address indexed seller,
        uint256 price
    );

    event PropertyDelisted(
        uint256 indexed propertyId, 
        address indexed seller
    );

    event PropertyPurchased(
        uint256 indexed listingId,
        uint256 indexed propertyId,
        address indexed buyer,
        uint256 price
    );

    function initialize(address registryAddress, address admin) public initializer {
        require(registryAddress != address(0), "Invalid registry address");
        require(admin != address(0), "Invalid admin address");

        __AccessControl_init();
        __ReentrancyGuard_init();

        registry_ = IPropertyRegistry(registryAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

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

    function delistProperty(uint256 propertyId) external {
        Listing storage listing = listings[propertyId];
        require(listing.active, "Property not listed");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;
        emit PropertyDelisted(propertyId, msg.sender);
    }

    function buyProperty(uint256 propertyId) external payable nonReentrant {
        Listing storage listing = listings[propertyId];
        require(listing.active, "Property not listed");
        require(msg.sender != listing.seller, "Seller cannot buy own property");
        require(msg.value == listing.price, "Incorrect payment amount");

        listing.active = false;

        (bool success, ) = payable(listing.seller).call{value: msg.value}("");
        require(success, "Payment transfer failed");

        registry_.safeTransferFrom(listing.seller, msg.sender, propertyId);

        emit PropertyPurchased(listing.listingId, propertyId, msg.sender, listing.price);
    }

    function getListing(uint256 propertyId) external view returns (Listing memory) {
        return listings[propertyId];
    }
}