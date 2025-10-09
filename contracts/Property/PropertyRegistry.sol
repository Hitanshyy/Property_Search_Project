// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { PropertyStorage } from "./Storage.sol";

/**
 * @title Property Registry Contract
 * @notice Mints NFTs for properties and stores IPFS metadata URIs.
 */
contract PropertyRegistry is Initializable, ERC721URIStorageUpgradeable, AccessControlUpgradeable, PropertyStorage {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    event PropertyMinted(
        uint256 indexed propertyId,
        address indexed owner,
        string tokenURI
    );

    function initialize(address admin) public initializer {
        require(admin != address(0), "Invalid admin address");

        __ERC721_init("PropertyRegistry", "PROP");
        __ERC721URIStorage_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(AGENT_ROLE, admin);
    }

    /**
     * @notice Mint a new property NFT (metadata stored on IPFS)
     * @param to Address of property owner
     * @param tokenURI IPFS hash with property details (location, valuation, etc.)
     */
    function mintProperty(address to, string memory tokenURI) external onlyRole(AGENT_ROLE) returns (uint256) {
        require(to != address(0), "Invalid owner address");
        require(bytes(tokenURI).length > 0, "IPFS hash required");

        _propertyIds++;
        uint256 newPropertyId = _propertyIds;

        _safeMint(to, newPropertyId);
        _setTokenURI(newPropertyId, tokenURI);

        properties[newPropertyId] = Property({
            id: newPropertyId,
            owner: to,
            location: "",
            price: 0,
            propertyType: "",
            size: 0,
            listed: false
        });

        originalOwner[newPropertyId] = to;
        ownerProperties[to].push(newPropertyId);

        emit PropertyMinted(newPropertyId, to, tokenURI);

        return newPropertyId;
    }

    /**
     * @notice Get total number of properties minted
     */
    function totalProperties() external view returns (uint256) {
        return _propertyIds;
    }

    /**
     * @dev Override supportsInterface for AccessControl
     */
    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721URIStorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }
}