// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PropertyStorage } from "./Storage.sol";
import { IPropertyRegistry } from "../IPropertyRegistry.sol";

/**
 * @title Property Search Contract
 * @notice Enables filtering and searching properties.
 */
contract PropertySearch is Initializable, PropertyStorage {

    function initialize(address registryAddress) public initializer {
        require(registryAddress != address(0), "Invalid registry");
        registry_ = IPropertyRegistry(registryAddress);
    }

    function filterProperties(
        string memory _location,
        uint256 _minPrice,
        uint256 _maxPrice,
        string memory _propertyType
    ) external view returns (Property[] memory) {
        uint256 count;
        // iterate all minted properties (1.._propertyIds)
        for (uint256 i = 1; i <= _propertyIds; i++) {
            if (properties[i].id != 0) {
                if (
                    (bytes(_location).length == 0 || keccak256(bytes(properties[i].location)) == keccak256(bytes(_location))) &&
                    properties[i].price >= _minPrice &&
                    properties[i].price <= _maxPrice &&
                    (bytes(_propertyType).length == 0 || keccak256(bytes(properties[i].propertyType)) == keccak256(bytes(_propertyType)))
                ) {
                    count++;
                }
            }
        }

        Property[] memory result = new Property[](count);
        uint256 index;
        for (uint256 i = 1; i <= _propertyIds; i++) {
            if (properties[i].id != 0) {
                if (
                    (bytes(_location).length == 0 || keccak256(bytes(properties[i].location)) == keccak256(bytes(_location))) &&
                    properties[i].price >= _minPrice &&
                    properties[i].price <= _maxPrice &&
                    (bytes(_propertyType).length == 0 || keccak256(bytes(properties[i].propertyType)) == keccak256(bytes(_propertyType)))
                ) {
                    result[index] = properties[i];
                    index++;
                }
            }
        }
        return result;
    }

    function getPropertiesByOwner(address _owner) external view returns (Property[] memory) {
        uint256[] memory ids = ownerProperties[_owner];
        Property[] memory result = new Property[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = properties[ids[i]];
        }
        return result;
    }
}