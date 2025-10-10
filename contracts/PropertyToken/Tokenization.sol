// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import { PropertyTokenStorage } from "./Storage.sol";
import { AccessModifiers } from "./AccessModifiers.sol";

contract PropertyToken is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PropertyTokenStorage,
    AccessModifiers
{
    using Strings for uint256;

    event PropertyTokenized(uint256 indexed propertyId, uint256 indexed tokenId, uint256 totalFractions, string uri);
    event PropertyURIUpdated(uint256 indexed tokenId, string newURI);
    event PropertyValueUpdated(uint256 indexed propertyId, uint256 newValue);
    event TradingToggled(uint256 indexed propertyId, bool enabled);

    function initialize(string memory baseURI, address admin) external initializer {
        __ERC1155_init(baseURI);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);

        _tokenCounter = 0;
    }

    // --- ADMIN FUNCTIONS --- //
    function pauseSystem() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpauseSystem() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function updatePropertyValue(uint256 propertyId, uint256 newValue) external onlyRole(ADMIN_ROLE) {
        require(_properties[propertyId].isActive, "Invalid property");
        _properties[propertyId].propertyValue = newValue;
        emit PropertyValueUpdated(propertyId, newValue);
    }

    function toggleTrading(uint256 propertyId, bool enabled) external onlyRole(ADMIN_ROLE) {
        require(_properties[propertyId].isActive, "Invalid property");
        _properties[propertyId].tradingEnabled = enabled;
        emit TradingToggled(propertyId, enabled);
    }

    function mintProperty(
        address to,
        uint256 propertyId,
        uint256 totalFractions,
        string memory propertyURI,
        uint256 propertyValue
    ) external nonReentrant onlyRole(ADMIN_ROLE) whenNotPaused {
        require(to != address(0), "Invalid address");
        require(totalFractions > 0, "Fractions must be > 0");
        require(!_properties[propertyId].isActive, "Property already tokenized");

        _tokenCounter += 1;
        uint256 tokenId = _tokenCounter;

        _mint(to, tokenId, totalFractions, "");
        _setURI(tokenId, propertyURI);

        _properties[propertyId] = PropertyInfo({
            propertyId: propertyId,
            uri: propertyURI,
            totalFractions: totalFractions,
            isActive: true,
            tradingEnabled: true,
            propertyValue: propertyValue
        });

        _tokenToProperty[tokenId] = propertyId;

        emit PropertyTokenized(propertyId, tokenId, totalFractions, propertyURI);
    }

    function _setURI(uint256 tokenId, string memory newuri) internal {
        _customURIs[tokenId] = newuri;
        emit PropertyURIUpdated(tokenId, newuri);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory customURI = _customURIs[tokenId];
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }

    // --- PROPERTY INFO --- //
    function getPropertyDetails(uint256 propertyId) external view returns (PropertyInfo memory) {
        return _properties[propertyId];
    }

    function _propertyToToken(uint256 propertyId) internal view returns (uint256) {
        for (uint256 i = 1; i <= _tokenCounter; i++) {
            if (_tokenToProperty[i] == propertyId) return i;
        }
        revert("Token not found");
    }

    // --- OVERRIDES --- //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}