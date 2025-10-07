// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { MarketPlaceStorage } from "./Storage.sol";
import { IPropertyRegistry } from "../IOwnership.sol";

/**
 * @title Offers Contract
 * @notice Allows buyers to make and manage offers for properties.
 */
contract Offers is Initializable, MarketPlaceStorage {

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

    function initialize(address registryAddress) public initializer {
        require(registryAddress != address(0), "Invalid registry");
        registry_ = IPropertyRegistry(registryAddress);
    }

    function makeOffer(uint256 propertyId) external payable {
        require(msg.value > 0, "Offer must be greater than zero");

        offers[propertyId].push(Offer({
            buyer: msg.sender,
            amount: msg.value,
            active: true
        }));

        emit OfferMade(propertyId, msg.sender, msg.value);
    }

    function cancelOffer(uint256 propertyId, uint256 index) external {
        Offer storage offer = offers[propertyId][index];
        require(offer.buyer == msg.sender, "Not your offer");
        require(offer.active, "Already inactive");

        offer.active = false;
        payable(msg.sender).transfer(offer.amount);

        emit OfferCancelled(propertyId, msg.sender);
    }

    function acceptOffer(uint256 propertyId, uint256 index) external {
        address owner = registry_.ownerOf(propertyId);
        require(owner == msg.sender, "Not property owner");

        Offer storage offer = offers[propertyId][index];
        require(offer.active, "Offer not active");

        offer.active = false;
        payable(msg.sender).transfer(offer.amount);
        registry_.safeTransferFrom(msg.sender, offer.buyer, propertyId);

        emit OfferAccepted(propertyId, msg.sender, offer.buyer, offer.amount);
    }
}