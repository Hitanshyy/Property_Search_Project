// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { OwnershipStorage } from "./Storage.sol";
import { IPropertyRegistry } from "../IPropertyRegistry.sol";

/**
 * @title Fractional Ownership Contract
 * @notice Allows property owners to fractionalize their property into shares.
 */
contract FractionalOwnership is Initializable, ReentrancyGuardUpgradeable, OwnershipStorage {

    event PropertyFractionalized(
        uint256 indexed propertyId,
        uint256 indexed fractionId,
        uint256 totalShares,
        uint256 sharePrice,
        address owner
    );

    event SharePurchased(
        uint256 indexed fractionId,
        address indexed buyer,
        uint256 amount,
        uint256 pricePaid
    );

    event ShareTransferred(
        uint256 indexed fractionId,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /**
     * @notice Initialize FractionalOwnership with property registry address
     * @param registryAddress Address of the PropertyRegistry contract
     */
    function initialize(address registryAddress) public initializer {
        require(registryAddress != address(0), "Invalid registry address");

        __ReentrancyGuard_init();

        registry_ = IPropertyRegistry(registryAddress);
    }

    /**
     * @notice Fractionalize a property into shares and place them for sale
     * @param _propertyId ID of the property to fractionalize
     * @param _totalShares Total shares to create
     * @param _sharePrice Price per share (in wei)
     */
    function fractionalizeProperty( uint256 _propertyId, uint256 _totalShares, uint256 _sharePrice) external nonReentrant {
        require(_totalShares > 0, "Total shares must be > 0");
        require(_sharePrice > 0, "Share price must be > 0");

        // Only property owner can fractionalize
        address propertyOwner = registry_.ownerOf(_propertyId);
        require(propertyOwner == msg.sender, "Only property owner can fractionalize");

        // Prevent duplicate fractionalization for same property
        uint256 existingFractionId = propertyToFractionId[_propertyId];
        require(existingFractionId == 0 || fractions[existingFractionId].propertyId != _propertyId, 
                "Property already fractionalized");

        // Increment fraction count
        fractionCount++;
        uint256 newFractionId = fractionCount;

        Fraction storage fraction = fractions[newFractionId];
        fraction.propertyId = _propertyId;
        fraction.totalShares = _totalShares;
        fraction.availableShares = _totalShares; // all shares initially available
        fraction.owner = msg.sender;
        fraction.sharePrice = _sharePrice;

        // Map property -> fraction
        propertyToFractionId[_propertyId] = newFractionId;

        emit PropertyFractionalized(_propertyId, newFractionId, _totalShares, _sharePrice, msg.sender);
    }

    /**
     * @notice Buy shares from a fractionalized property
     * @param _fractionId ID of the fraction
     * @param _shareAmount Number of shares to purchase
     */
    function buyShare(uint256 _fractionId, uint256 _shareAmount) external payable nonReentrant {
        require(_shareAmount > 0, "Share amount must be > 0");
        require(_fractionId > 0 && _fractionId <= fractionCount, "Invalid fractionId");

        Fraction storage fraction = fractions[_fractionId];
        require(fraction.availableShares >= _shareAmount, "Not enough shares available");
        uint256 totalPrice = _shareAmount * fraction.sharePrice;
        require(msg.value == totalPrice, "Incorrect payment amount");

        // Assign shares to buyer and reduce available shares
        fraction.shares[msg.sender] += _shareAmount;
        fraction.availableShares -= _shareAmount;

        // Transfer funds immediately to fraction owner (seller)
        (bool sent, ) = payable(fraction.owner).call{value: msg.value}("");
        require(sent, "Payment transfer failed");

        emit SharePurchased(_fractionId, msg.sender, _shareAmount, msg.value);
    }

    /**
     * @notice Transfer owned shares to another address
     * @param _fractionId ID of the fraction
     * @param _to Recipient address
     * @param _amount Number of shares to transfer
     */
    function transferShare(uint256 _fractionId, address _to, uint256 _amount) external nonReentrant {
        require(_to != address(0), "Invalid recipient");
        require(_fractionId > 0 && _fractionId <= fractionCount, "Invalid fractionId");
        Fraction storage fraction = fractions[_fractionId];

        require(fraction.shares[msg.sender] >= _amount, "Insufficient shares");

        fraction.shares[msg.sender] -= _amount;
        fraction.shares[_to] += _amount;

        emit ShareTransferred(_fractionId, msg.sender, _to, _amount);
    }

    /**
     * @notice Set share price for a fraction (only fraction owner)
     * @param _fractionId ID of the fraction
     * @param _newPrice New price per share in wei
     */
    function setSharePrice(uint256 _fractionId, uint256 _newPrice) external {
        require(_fractionId > 0 && _fractionId <= fractionCount, "Invalid fractionId");
        Fraction storage fraction = fractions[_fractionId];
        require(msg.sender == fraction.owner, "Only fraction owner can set price");
        require(_newPrice > 0, "Price must be > 0");

        fraction.sharePrice = _newPrice;
    }

    /**
     * @notice Get the number of shares owned by an address for a fraction
     * @param _fractionId ID of the fraction
     * @param _user Address to query
     */
    function getShareBalance(uint256 _fractionId, address _user) external view returns (uint256) {
        require(_fractionId > 0 && _fractionId <= fractionCount, "Invalid fractionId");
        return fractions[_fractionId].shares[_user];
    }

    /**
     * @notice Get fraction id for a property (0 if not fractionalized)
     * @param _propertyId ID of the property
     */
    function getFractionIdByProperty(uint256 _propertyId) external view returns (uint256) {
        return propertyToFractionId[_propertyId];
    }
}