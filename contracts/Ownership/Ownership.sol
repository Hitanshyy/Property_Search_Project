// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnershipStorage } from "./Storage.sol";
import { IPropertyRegistry } from "../IPropertyRegistry.sol";

/**
 * @title Ownership Contract
 * @notice Handles property ownership transfers and maintains ownership history
*/
contract Ownership is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, OwnershipStorage {
    // Role identifiers
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    event OwnershipTransferred(
        uint256 indexed propertyId,
        address indexed from,
        address indexed to
    );

    function initialize(address registryAddress, address admin) public initializer {
        require(registryAddress != address(0), "Invalid registry address");
        require(admin != address(0), "Invalid admin address");

        __AccessControl_init();
        __ReentrancyGuard_init();

        registry_ = IPropertyRegistry(registryAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(AGENT_ROLE, admin);
    }

    /**
     * @notice Transfers ownership of a property NFT via the registry
     * @dev Only AGENT_ROLE can call. Reentrancy-protected.
     */
    function transferOwnership(uint256 propertyId, address newOwner) external onlyRole(AGENT_ROLE) nonReentrant {
        require(newOwner != address(0), "Invalid new owner");

        address currentOwner = registry_.ownerOf(propertyId);
        require(currentOwner != newOwner, "Already the owner");

        // Transfer NFT via ERC721 registry. Registry's _afterTokenTransfer will keep storage in sync.
        registry_.safeTransferFrom(currentOwner, newOwner, propertyId);

        emit OwnershipTransferred(propertyId, currentOwner, newOwner);
    }

    function getOwnershipHistory(uint256 propertyId) external view returns (address[] memory) {
        return ownershipHistory_[propertyId];
    }
} 
