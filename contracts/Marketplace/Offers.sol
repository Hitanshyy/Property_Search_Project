// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { MarketPlaceStorage } from "./Storage.sol";
import { IPropertyRegistry } from "../IPropertyRegistry.sol";
import { Ownership } from "../Ownership/Ownership.sol";

/**
 * @title Offers Contract
 * @notice Allows buyers to make and manage offers
 */
contract Offers is Initializable, ReentrancyGuardUpgradeable, MarketPlaceStorage {

    event OfferMade(
        uint256 indexed propertyId, 
        address indexed buyer, 
        uint256 amount
    );

    event OfferCancelled(
        uint256 indexed propertyId, 
        address indexed buyer
    );

    event OfferAccepted(
        uint256 indexed propertyId, 
        address indexed seller, 
        address indexed buyer, 
        uint256 amount
    );

    function initialize(address registryAddress, address ownershipAddress) public initializer {
        __ReentrancyGuard_init();
        require(registryAddress != address(0), "Invalid registry");
        require(ownershipAddress != address(0), "Invalid ownership");

        registry_ = IPropertyRegistry(registryAddress);
        ownership_ = Ownership(ownershipAddress);
    }

    function makeOffer(uint256 propertyId) external payable {
        require(msg.value > 0, "Offer must be > 0");

        offers[propertyId].push(Offer(msg.sender, msg.value, true));

        emit OfferMade(propertyId, msg.sender, msg.value);
    }

    function cancelOffer(uint256 propertyId, uint256 index) external nonReentrant {
        Offer storage offer = offers[propertyId][index];
        require(offer.active, "Already inactive");
        require(offer.buyer == msg.sender, "Not your offer");

        offer.active = false;
        (bool success, ) = payable(msg.sender).call{value: offer.amount}("");
        require(success, "Refund failed");

        emit OfferCancelled(propertyId, msg.sender);
    }

    function acceptOffer(uint256 propertyId, uint256 index) external nonReentrant {
        address owner = registry_.ownerOf(propertyId);
        require(owner == msg.sender, "Not property owner");

        Offer storage offer = offers[propertyId][index];
        require(offer.active, "Offer inactive");

        offer.active = false;

        ownership_.transferOwnership(propertyId, offer.buyer);

        (bool success, ) = payable(msg.sender).call{value: offer.amount}("");
        require(success, "Payment failed");

        emit OfferAccepted(propertyId, msg.sender, offer.buyer, offer.amount);
    }
}