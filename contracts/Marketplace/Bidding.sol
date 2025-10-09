// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { MarketPlaceStorage } from "./Storage.sol";
import { IPropertyRegistry } from "../IPropertyRegistry.sol";

/**
 * @title Bidding Contract
 * @notice Supports auction-style property sales.
 */
contract Bidding is Initializable, MarketPlaceStorage, ReentrancyGuardUpgradeable {
    event AuctionCreated(
        uint256 indexed propertyId, 
        address indexed seller, 
        uint256 startPrice, 
        uint256 endTime
    );

    event BidPlaced(
        uint256 indexed propertyId, 
        address indexed bidder, 
        uint256 amount
    );

    event AuctionEnded(
        uint256 indexed propertyId, 
        address indexed winner, 
        uint256 finalBid
    );

    function initialize(address registryAddress) public initializer {
        __ReentrancyGuard_init();
        require(registryAddress != address(0), "Invalid registry");
        registry_ = IPropertyRegistry(registryAddress);
    }

    function createAuction(uint256 propertyId, uint256 startPrice, uint256 duration) external {
        require(duration > 0, "Invalid duration");
        address owner = registry_.ownerOf(propertyId);
        require(owner == msg.sender, "Not property owner");

        auctions[propertyId] = Auction({
            seller: msg.sender,
            startPrice: startPrice,
            highestBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + duration,
            active: true
        });

        emit AuctionCreated(propertyId, msg.sender, startPrice, block.timestamp + duration);
    }

    function placeBid(uint256 propertyId) external payable nonReentrant {
        Auction storage auction = auctions[propertyId];
        require(auction.active, "Auction inactive");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.value > auction.highestBid && msg.value >= auction.startPrice, "Low bid");

        if (auction.highestBid > 0) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(propertyId, msg.sender, msg.value);
    }

    function endAuction(uint256 propertyId) external nonReentrant {
        Auction storage auction = auctions[propertyId];
        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction still ongoing");

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            payable(auction.seller).transfer(auction.highestBid);

            registry_.safeTransferFrom(auction.seller, auction.highestBidder, propertyId);

            emit AuctionEnded(propertyId, auction.highestBidder, auction.highestBid);
        } else {
            emit AuctionEnded(propertyId, address(0), 0);
        }
    }
}