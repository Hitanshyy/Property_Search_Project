// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { OwnershipStorage } from "./Storage.sol";

/**
 * @title Fractional Ownership Contract
 * @notice Allows property owners to fractionalize their property into shares.
 */
contract FractionalOwnership is Initializable, ReentrancyGuardUpgradeable, OwnershipStorage {

    event PropertyFractionalized(
        uint256 indexed propertyId, 
        uint256 totalShares, 
        address owner
    );

    event SharePurchased(
        uint256 indexed fractionId, 
        address indexed buyer, 
        uint256 amount
    );

    event ShareTransferred(
        uint256 indexed fractionId, 
        address indexed from, 
        address indexed to, 
        uint256 amount
    );

    function initialize() public initializer {
        __ReentrancyGuard_init();
    }

    function fractionalizeProperty(uint256 _propertyId, uint256 _totalShares) external nonReentrant {
        require(_totalShares > 0, "Total shares must be > 0");

        fractionCount++;
        Fraction storage fraction = fractions[fractionCount];
        fraction.propertyId = _propertyId;
        fraction.totalShares = _totalShares;
        fraction.shares[msg.sender] = _totalShares;

        emit PropertyFractionalized(_propertyId, _totalShares, msg.sender);
    }

    function buyShare(uint256 _fractionId, uint256 _shareAmount) external payable nonReentrant {
        Fraction storage fraction = fractions[_fractionId];
        require(_shareAmount > 0 && fraction.totalShares >= _shareAmount, "Invalid share amount");
        fraction.shares[msg.sender] += _shareAmount;
        fraction.totalShares -= _shareAmount;

        emit SharePurchased(_fractionId, msg.sender, _shareAmount);
    }

    function transferShare(uint256 _fractionId, address _to, uint256 _amount) external nonReentrant {
        Fraction storage fraction = fractions[_fractionId];
        require(fraction.shares[msg.sender] >= _amount, "Insufficient shares");

        fraction.shares[msg.sender] -= _amount;
        fraction.shares[_to] += _amount;

        emit ShareTransferred(_fractionId, msg.sender, _to, _amount);
    }
}