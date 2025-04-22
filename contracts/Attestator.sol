// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ISchemaRegistry } from "./interfaces/EAS/ISchemaRegistry.sol";
import { ISchemaResolver } from "./interfaces/EAS/ISchemaResolver.sol";
import { IEAS, MultiAttestationRequest } from "./interfaces/EAS/IEAS.sol";
import { IAttestator } from "./interfaces/IAttestator.sol";
import { Errors } from "./lib/Errors.sol";

/// @title Attestator
/// @notice The Attestator is a contract that allows to do multiple attestations using a single call and register schemas
contract Attestator is IAttestator, Ownable {
    ISchemaRegistry public schemaRegistry;
    IEAS public eas;

    mapping(address => bool) public approvedCallers;

    modifier onlyApprovedCaller() {
        if (!approvedCallers[msg.sender]) revert Errors.NotApprovedCaller();
        _;
    }

    /// @notice Constructor
    /// @param _owner The owner of the contract
    /// @param _schemaRegistry The address of the schema registry
    /// @param _eas The address of the EAS contract
    constructor(address _owner, address _schemaRegistry, address _eas) Ownable(_owner) {
        if (_schemaRegistry == address(0)) revert Errors.ZeroSchemaRegistry();
        if (_eas == address(0)) revert Errors.ZeroEAS();

        schemaRegistry = ISchemaRegistry(_schemaRegistry);
        eas = IEAS(_eas);
    }

    /// @notice Sets the schema registry
    /// @param _schemaRegistry The address of the schema registry
    function setSchemaRegistry(address _schemaRegistry) external onlyOwner {
        if (_schemaRegistry == address(0)) revert Errors.ZeroSchemaRegistry();
        schemaRegistry = ISchemaRegistry(_schemaRegistry);
        emit SchemaRegistrySet(_schemaRegistry);
    }

    /// @notice Sets the EAS contract
    /// @param _eas The address of the EAS contract
    function setEAS(address _eas) external onlyOwner {
        if (_eas == address(0)) revert Errors.ZeroEAS();
        eas = IEAS(_eas);
        emit EASSet(_eas);
    }

    /// @notice Sets an approved caller
    /// @param _caller The address of the caller to set
    /// @param _approved Whether the caller is approved
    function setApprovedCaller(address _caller, bool _approved) external onlyOwner {
        if (_caller == address(0)) revert Errors.ZeroCaller();
        approvedCallers[_caller] = _approved;
        emit ApprovedCallerSet(_caller, _approved);
    }

    /// @notice Attests to multiple schemas.
    /// @param multiRequests The arguments of the multi attestation requests. The requests should be grouped by distinct
    ///        schema ids to benefit from the best batching optimization.
    /// @return The UIDs of the new attestations.
    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external onlyApprovedCaller payable returns (bytes32[] memory) {
        return eas.multiAttest{value: msg.value}(multiRequests);
    }

    /// @notice Submits and reserves a new schema
    /// @param schema The schema data schema
    /// @param resolver An optional schema resolver
    /// @param revocable Whether the schema allows revocations explicitly
    /// @return schemaId The UID of the new schema
    function registerSchema(string calldata schema, ISchemaResolver resolver, bool revocable) external onlyApprovedCaller returns (bytes32 schemaId) {
        schemaId = schemaRegistry.register(schema, resolver, revocable);
    } 
}