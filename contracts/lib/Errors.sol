// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @title Errors Library
/// @notice Library for all contract errors.
library Errors {
    /// @notice The caller is not approved.
    error Attestator__NotApprovedCaller();
    /// @notice The schema registry is zero address.
    error Attestator__ZeroSchemaRegistry();
    /// @notice The EAS is zero address.
    error Attestator__ZeroEAS();
    /// @notice The caller is zero address.
    error Attestator__ZeroCaller();
}
