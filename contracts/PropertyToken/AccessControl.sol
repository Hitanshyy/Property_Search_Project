// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RoleManager is Initializable, AccessControlUpgradeable, PausableUpgradeable {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant VARA_COMPLIANCE_ROLE = keccak256("VARA_COMPLIANCE_ROLE");

    struct AgentProfile {
        address agent;
        string name;
        uint256 registeredAt;
        bool verified;
        uint256 performanceScore;
        bool active;
        string licenseId; // 🆕 License or registration ID
        string licenseDocument; // 🆕 License document hash or metadata
    }

    struct DeveloperProfile {
        address developer;
        string name;
        uint256 onboardedAt;
        bool active;
    }

    mapping(address => AgentProfile) public agents;
    mapping(address => DeveloperProfile) public developers;
    mapping(address => bool) public blacklisted;

    event AgentRegistered(address indexed agent, string name, uint256 timestamp);
    event AgentVerified(address indexed agent, bool status);
    event DeveloperOnboarded(address indexed developer, string name, uint256 timestamp);
    event UserBlacklisted(address indexed user, bool status);
    event AgentPerformanceUpdated(address indexed agent, uint256 score);
    event AgentLicenseUpdated(address indexed agent, string licenseId, string documentHash); // 🆕
    event SystemPaused(address indexed admin);
    event SystemUnpaused(address indexed admin);

    function initialize(address admin) external initializer {
        __AccessControl_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    function pauseSystem() external onlyRole(ADMIN_ROLE) {
        _pause();
        emit SystemPaused(msg.sender);
    }

    function unpauseSystem() external onlyRole(ADMIN_ROLE) {
        _unpause();
        emit SystemUnpaused(msg.sender);
    }

    function blacklistUser(address user, bool status) external onlyRole(ADMIN_ROLE) {
        require(user != address(0), "Invalid address");
        blacklisted[user] = status;
        emit UserBlacklisted(user, status);
    }

    function registerAgent(address agent, string memory name) external onlyRole(ADMIN_ROLE) {
        require(agent != address(0), "Invalid address");
        require(!agents[agent].active, "Agent exists");

        agents[agent] = AgentProfile(agent, name, block.timestamp, false, 0, true, "", "");
        _grantRole(AGENT_ROLE, agent);
        emit AgentRegistered(agent, name, block.timestamp);
    }

    function updateAgentLicense(address agent, string memory licenseId, string memory documentHash)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(agent != address(0) && agents[agent].active, "Agent invalid");
        agents[agent].licenseId = licenseId;
        agents[agent].licenseDocument = documentHash;
        emit AgentLicenseUpdated(agent, licenseId, documentHash);
    }

    function verifyAgent(address agent, bool status) external onlyRole(ADMIN_ROLE) {
        require(agent != address(0) && agents[agent].active, "Agent invalid");
        agents[agent].verified = status;
        emit AgentVerified(agent, status);
    }

    function updateAgentPerformance(address agent, uint256 score) external onlyRole(ADMIN_ROLE) {
        require(agent != address(0) && agents[agent].active, "Agent invalid");
        agents[agent].performanceScore = score;
        emit AgentPerformanceUpdated(agent, score);
    }

    function deactivateAgent(address agent) external onlyRole(ADMIN_ROLE) {
        require(agent != address(0) && agents[agent].active, "Agent invalid");
        agents[agent].active = false;
        revokeRole(AGENT_ROLE, agent);
    }

    function reactivateAgent(address agent) external onlyRole(ADMIN_ROLE) {
        require(agent != address(0) && !agents[agent].active, "Agent already active");
        agents[agent].active = true;
        _grantRole(AGENT_ROLE, agent);
    }

    function onboardDeveloper(address developer, string memory name) external onlyRole(ADMIN_ROLE) {
        require(developer != address(0) && !developers[developer].active, "Developer invalid");
        developers[developer] = DeveloperProfile(developer, name, block.timestamp, true);
        _grantRole(DEVELOPER_ROLE, developer);
        emit DeveloperOnboarded(developer, name, block.timestamp);
    }

    function deactivateDeveloper(address developer) external onlyRole(ADMIN_ROLE) {
        require(developer != address(0) && developers[developer].active, "Developer invalid");
        developers[developer].active = false;
        revokeRole(DEVELOPER_ROLE, developer);
    }

    function reactivateDeveloper(address developer) external onlyRole(ADMIN_ROLE) {
        require(developer != address(0) && !developers[developer].active, "Developer invalid");
        developers[developer].active = true;
        _grantRole(DEVELOPER_ROLE, developer);
    }

    function isBlacklisted(address user) external view returns (bool) {
        return blacklisted[user];
    }

    function isAgentVerified(address agent) external view returns (bool) {
        return agents[agent].verified;
    }

    function isAgentActive(address agent) external view returns (bool) {
        return agents[agent].active;
    }

    function isDeveloperActive(address developer) external view returns (bool) {
        return developers[developer].active;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}