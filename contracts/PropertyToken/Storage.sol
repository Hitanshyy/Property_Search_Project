// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract PropertyTokenStorage is AccessControlUpgradeable {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct PropertyInfo {
        uint256 propertyId;
        string uri;
        uint256 totalFractions;
        bool isActive;
        bool tradingEnabled;
        uint256 propertyValue;
    }

    uint256 internal _tokenCounter;

    mapping(address => bool) public kycVerified;
    mapping(address => bool) public accreditedInvestors;

    mapping(uint256 => PropertyInfo) internal _properties;
    mapping(uint256 => uint256) internal _tokenToProperty;

    mapping(address => mapping(uint256 => uint256)) internal _fractionBalances;
    mapping(uint256 => address[]) internal _propertyInvestors;
    mapping(uint256 => string) internal _customURIs;

    mapping(uint256 => mapping(address => uint256)) public fractionBalances;
    mapping(uint256 => address[]) public propertyInvestors;

    mapping(uint256 => mapping(address => uint256)) internal fractionBalances_;
    mapping(uint256 => address[]) internal propertyInvestors_;

    function getProperty(uint256 propertyId) external view returns (PropertyInfo memory) {
        return _properties[propertyId];
    }
}