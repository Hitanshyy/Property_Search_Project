// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin upgradeable libraries
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Interface to interact with PropertyRegistry
interface IPropertyRegistry {
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

/// @title Ownership Contract
/// @notice Handles transfer of property ownership and keeps immutable records
contract Ownership is Initializable, AccessControlUpgradeable {
    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    // Reference to PropertyRegistry
    IPropertyRegistry public registry;

    // Ownership history: propertyId => list of previous owners
    mapping(uint256 => address[]) private ownershipHistory;

    // Events
    event OwnershipTransferred(uint256 indexed propertyId, address indexed from, address indexed to);

    /// @notice Initialize contract with PropertyRegistry address and admin
    function initialize(address registryAddress, address admin) public initializer {
        __AccessControl_init();

        require(registryAddress != address(0), "Invalid registry address");

        registry = IPropertyRegistry(registryAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    /// @notice Transfer property ownership
    /// @param propertyId ID of the property NFT
    /// @param newOwner Address of the new owner
    function transferOwnership(uint256 propertyId, address newOwner) external onlyRole(AGENT_ROLE) {
        require(newOwner != address(0), "Invalid new owner");

        address currentOwner = registry.ownerOf(propertyId);
        require(currentOwner != newOwner, "Already the owner");

        // Record current owner in history
        ownershipHistory[propertyId].push(currentOwner);

        // Transfer NFT in PropertyRegistry
        registry.safeTransferFrom(currentOwner, newOwner, propertyId);

        emit OwnershipTransferred(propertyId, currentOwner, newOwner);
    }

    /// @notice Get full ownership history of a property
    /// @param propertyId ID of the property NFT
    /// @return Array of previous owners
    function getOwnershipHistory(uint256 propertyId) external view returns (address[] memory) {
        return ownershipHistory[propertyId];
    }
}
