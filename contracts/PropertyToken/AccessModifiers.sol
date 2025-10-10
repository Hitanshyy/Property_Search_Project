// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { KYCVerifier } from "./KycVerifier.sol";
import { RoleManager } from "./AccessControl.sol";

abstract contract AccessModifiers {

    bytes32 internal constant VARA_COMPLIANCE_ROLE = keccak256("VARA_COMPLIANCE_ROLE");

    address public kycVerifier;
    address public roleManager;

    modifier onlyKYCVerified(address user) {
        require(KYCVerifier(kycVerifier).isKYCVerified(user), "User not KYC verified");
        _;
    }

    modifier onlyAccredited(address user) {
        require(KYCVerifier(kycVerifier).accreditedInvestors(user), "User not accredited");
        _;
    }

    modifier onlyAuthorizedMinter() {
        require(
            RoleManager(roleManager).hasRole(VARA_COMPLIANCE_ROLE, msg.sender),
            "Not authorized to mint"
        );
        _;
    }
}