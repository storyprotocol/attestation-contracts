// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {ISchemaRegistry} from "@ethereum-attestation-service/eas-contracts/contracts/ISchemaRegistry.sol";
import {ISchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/ISchemaResolver.sol";
import {
    IEAS,
    MultiAttestationRequest,
    MultiRevocationRequest
} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {IAttestator} from "./interfaces/IAttestator.sol";
import {Errors} from "./lib/Errors.sol";

/// @title Attestator
/// @notice The Attestator is a contract that allows to do multiple attestations using a single call and register schemas
contract Attestator is IAttestator, OwnableUpgradeable, UUPSUpgradeable {
    /// @dev Storage structure for the Attestator
    /// @custom:storage-location erc7201:story-protocol.Attestator
    struct AttestatorStorage {
        ISchemaRegistry schemaRegistry;
        IEAS eas;
        mapping(address => bool) approvedCallers;
    }

    // keccak256(abi.encode(uint256(keccak256("story-protocol.Attestator")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant AttestatorStorageLocation =
        0x263752e8bbde01827b1c6c4b537d12adfc292bc66c084595527eb2e531456500;

    /// @notice Constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    /// @param _owner The owner of the contract
    /// @param _schemaRegistry The address of the schema registry
    /// @param _eas The address of the EAS contract
    function initialize(address _owner, address _schemaRegistry, address _eas) external initializer {
        if (_schemaRegistry == address(0)) revert Errors.Attestator__ZeroSchemaRegistry();
        if (_eas == address(0)) revert Errors.Attestator__ZeroEAS();

        AttestatorStorage storage $ = _getAttestatorStorage();

        $.schemaRegistry = ISchemaRegistry(_schemaRegistry);
        $.eas = IEAS(_eas);

        __UUPSUpgradeable_init();
        __Ownable_init(_owner);
    }

    /// @notice Sets the schema registry
    /// @param _schemaRegistry The address of the schema registry
    function setSchemaRegistry(address _schemaRegistry) external onlyOwner {
        if (_schemaRegistry == address(0)) revert Errors.Attestator__ZeroSchemaRegistry();
        AttestatorStorage storage $ = _getAttestatorStorage();

        $.schemaRegistry = ISchemaRegistry(_schemaRegistry);

        emit SchemaRegistrySet(_schemaRegistry);
    }

    /// @notice Sets the EAS contract
    /// @param _eas The address of the EAS contract
    function setEAS(address _eas) external onlyOwner {
        if (_eas == address(0)) revert Errors.Attestator__ZeroEAS();
        AttestatorStorage storage $ = _getAttestatorStorage();

        $.eas = IEAS(_eas);

        emit EASSet(_eas);
    }

    /// @notice Sets an approved caller
    /// @param _caller The address of the caller to set
    /// @param _approved Whether the caller is approved
    function setApprovedCaller(address _caller, bool _approved) external onlyOwner {
        if (_caller == address(0)) revert Errors.Attestator__ZeroCaller();
        AttestatorStorage storage $ = _getAttestatorStorage();

        $.approvedCallers[_caller] = _approved;

        emit ApprovedCallerSet(_caller, _approved);
    }

    /// @notice Attests to multiple schemas.
    /// @param multiRequests The arguments of the multi attestation requests. The requests should be grouped by distinct
    ///        schema ids to benefit from the best batching optimization.
    /// @return The UIDs of the new attestations.
    function multiAttest(MultiAttestationRequest[] calldata multiRequests)
        external
        payable
        returns (bytes32[] memory)
    {
        AttestatorStorage storage $ = _getAttestatorStorage();
        if (!$.approvedCallers[msg.sender]) revert Errors.Attestator__NotApprovedCaller();

        return $.eas.multiAttest{value: msg.value}(multiRequests);
    }

    /// @notice Revokes existing attestations to multiple schemas.
    /// @param multiRequests The arguments of the multi revocation requests. The requests should be grouped by distinct
    ///     schema ids to benefit from the best batching optimization.
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable {
        AttestatorStorage storage $ = _getAttestatorStorage();
        if (!$.approvedCallers[msg.sender]) revert Errors.Attestator__NotApprovedCaller();

        $.eas.multiRevoke{value: msg.value}(multiRequests);
    }

    /// @notice Submits and reserves a new schema
    /// @param schema The schema data schema
    /// @param resolver An optional schema resolver
    /// @param revocable Whether the schema allows revocations explicitly
    /// @return schemaId The UID of the new schema
    function registerSchema(string calldata schema, ISchemaResolver resolver, bool revocable)
        external
        returns (bytes32 schemaId)
    {
        AttestatorStorage storage $ = _getAttestatorStorage();
        if (!$.approvedCallers[msg.sender]) revert Errors.Attestator__NotApprovedCaller();

        schemaId = $.schemaRegistry.register(schema, resolver, revocable);
    }

    /// @dev Returns the storage struct of Attestator.
    function _getAttestatorStorage() private pure returns (AttestatorStorage storage $) {
        assembly {
            $.slot := AttestatorStorageLocation
        }
    }

    /// @notice Returns the schema registry
    /// @return schemaRegistry The address of the schema registry
    function schemaRegistry() public view returns (ISchemaRegistry) {
        return _getAttestatorStorage().schemaRegistry;
    }

    /// @notice Returns the EAS contract
    /// @return eas The address of the EAS contract
    function eas() public view returns (IEAS) {
        return _getAttestatorStorage().eas;
    }

    /// @notice Returns whether an address is an approved caller
    /// @param caller The address to check
    /// @return isApproved Whether the address is an approved caller
    function approvedCallers(address caller) public view returns (bool) {
        return _getAttestatorStorage().approvedCallers[caller];
    }

    /// @dev Hook to authorize the upgrade according to UUPSUpgradeable
    /// @param newImplementation The address of the new implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
