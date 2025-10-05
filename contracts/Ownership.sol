// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PropertySearchStorage } from "./Storage.sol";
import { IPropertyRegistry } from "./IOwnership.sol";

/**
 * @title Ownership Contract
 * @notice Handles property ownership transfers and maintains ownership history
*/
contract Ownership is Initializable, AccessControlUpgradeable, PropertySearchStorage {
    // Role identifiers
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    /**
     * @dev Event emitted when Ownership is transferred.
     * @param propertyId ID of the property NFT
     * @param from is the from address.
     * @param to is the to address.
    */
    event OwnershipTransferred(
        uint256 indexed propertyId, 
        address indexed from, 
        address indexed to
    );

    /**
     * @notice Initializes the contract with registry address and admin
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
     * @notice Transfers ownership of a property NFT
     * @dev Only an address with AGENT_ROLE can call this function
     * @param propertyId ID of the property NFT
     * @param newOwner Address of the new owner
    */
    function transferOwnership(uint256 propertyId, address newOwner) external onlyRole(AGENT_ROLE) {
        require(newOwner != address(0), "Invalid new owner");

        address currentOwner = registry_.ownerOf(propertyId);
        require(currentOwner != newOwner, "Already the owner");

        // Record current owner in history
        ownershipHistory_[propertyId].push(currentOwner);

        // Transfer NFT via PropertyRegistry contract
        registry_.safeTransferFrom(currentOwner, newOwner, propertyId);

        emit OwnershipTransferred(propertyId, currentOwner, newOwner);
    }

    /** 
     * @notice Returns the ownership history of a property
     * @param propertyId ID of the property NFT
     * @return Array of previous owners
    */
    function getOwnershipHistory(uint256 propertyId) external view returns (address[] memory) {
        return ownershipHistory_[propertyId];
    }
}
