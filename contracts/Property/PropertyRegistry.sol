// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin upgradeable libraries
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { PropertyStorage } from "./Storage.sol";
/**
 * @title Property Registry Contract
 * @notice Mints NFTs for properties and stores IPFS metadata URIs
*/
contract PropertyRegistry is Initializable, ERC721URIStorageUpgradeable, AccessControlUpgradeable, PropertyStorage{
    // Role identifiers
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    /**
     * @dev Event emitted when a new property NFT is minted.
     * @param propertyId ID of the newly minted property NFT.
     * @param owner Address of the property owner receiving the NFT.
     * @param tokenURI IPFS hash or URI pointing to the property metadata.
    */
    event PropertyMinted(
        uint256 indexed propertyId, 
        address indexed owner, 
        string tokenURI
    );

    /**
     * @notice Initialize the contract (for proxy deployment)
     * @param admin Address of the admin
    */
    function initialize(address admin) public initializer {
        __ERC721_init("PropertyRegistry", "PROP");
        __ERC721URIStorage_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    /** 
     * @notice Mint a new property NFT (metadata stored on IPFS)
     * @param to Address of property owner
     * @param tokenURI IPFS hash with property details (location, valuation, etc.)
    */
    function mintProperty(address to, string memory tokenURI) external onlyRole(AGENT_ROLE) returns (uint256) {
        require(to != address(0), "Invalid owner address");
        require(bytes(tokenURI).length > 0, "IPFS hash required");

        _propertyIds += 1;
        uint256 newPropertyId = _propertyIds;

        _safeMint(to, newPropertyId);
        _setTokenURI(newPropertyId, tokenURI);

        originalOwner[newPropertyId] = to;

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
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721URIStorageUpgradeable, AccessControlUpgradeable) returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId) 
            || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

}
