// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { IEAS, MultiAttestationRequest } from "./EAS/IEAS.sol";
import { ISchemaResolver } from "./EAS/ISchemaResolver.sol";

/// @title IAttestator
/// @notice The interface of the Attestator contract
interface IAttestator {
    /// @notice Sets the schema registry
    /// @param _schemaRegistry The address of the schema registry
    function setSchemaRegistry(address _schemaRegistry) external;

    /// @notice Sets the EAS contract
    /// @param _eas The address of the EAS contract
    function setEAS(address _eas) external;

    /// @notice Sets an approved caller
    /// @param _caller The address of the caller to set
    /// @param _approved Whether the caller is approved
    function setApprovedCaller(address _caller, bool _approved) external;

    /// @notice Attests to multiple schemas.
    /// @param multiRequests The arguments of the multi attestation requests. The requests should be grouped by distinct
    ///        schema ids to benefit from the best batching optimization.
    /// @return The UIDs of the new attestations.
    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external payable returns (bytes32[] memory);

    /// @notice Submits and reserves a new schema
    /// @param schema The schema data schema
    /// @param resolver An optional schema resolver
    /// @param revocable Whether the schema allows revocations explicitly
    /// @return schemaId The UID of the new schema
    function registerSchema(string calldata schema, ISchemaResolver resolver, bool revocable) external returns (bytes32 schemaId);
}