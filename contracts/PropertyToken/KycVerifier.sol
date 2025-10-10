// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PropertyTokenStorage } from "./Storage.sol";
import { RoleManager } from "./AccessControl.sol";

contract KYCVerifier is Initializable, AccessControlUpgradeable, PropertyTokenStorage {

    bytes32 private constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 private constant VARA_COMPLIANCE_ROLE = keccak256("VARA_COMPLIANCE_ROLE");
    
    address public roleManager;

    event KYCApproved(address indexed user, string documentHash);
    event KYCRevoked(address indexed user);

    function initialize(address _admin) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
    }

    function setRoleManager(address _roleManager) external onlyRole(ADMIN_ROLE) {
        require(_roleManager != address(0), "Invalid RoleManager");
        roleManager = _roleManager;
    }

    modifier onlyAuthorizedAgent() {
        RoleManager rm = RoleManager(roleManager); // cast address to contract
        require(
            rm.hasRole(AGENT_ROLE, msg.sender) ||
            rm.hasRole(VARA_COMPLIANCE_ROLE, msg.sender) ||
            hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized"
        );
        _;
    }

    function approveKYC(address user, string memory documentHash) external onlyAuthorizedAgent {
        require(user != address(0), "Invalid address");
        kycVerified[user] = true;
        emit KYCApproved(user, documentHash);
    }

    function revokeKYC(address user) external onlyAuthorizedAgent {
        require(user != address(0), "Invalid address");
        kycVerified[user] = false;
        emit KYCRevoked(user);
    }

    function isKYCVerified(address user) external view returns (bool) {
        return kycVerified[user];
    }
}