// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

import {ISchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/ISchemaResolver.sol";
import {
    MultiAttestationRequest,
    AttestationRequestData,
    MultiRevocationRequest,
    RevocationRequestData
} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

import {Attestator} from "../../contracts/Attestator.sol";
import {Errors} from "../../contracts/lib/Errors.sol";

contract AttestatorTest is Test {
    Attestator public attestator;
    address public owner;
    address public approvedCaller;
    address public eas;
    address public schemaRegistry;

    function setUp() public {
        // Fork the desired network where EAS contracts are deployed
        uint256 forkId = vm.createFork("https://mainnet.storyrpc.io/");
        vm.selectFork(forkId);

        // Mainnet
        // EAS related addresses
        eas = 0x5bF79CECE7D1C9DA45a9F0dE480589ecCE1B48c8;
        schemaRegistry = 0x5F983ab12EE78535C9067dE1CDFc7C511320fB7d;

        // Deploy the Attestator contract
        owner = makeAddr("owner");
        address attestatorImpl = address(new Attestator());
        attestator = Attestator(
            address(
                new ERC1967Proxy(attestatorImpl, abi.encodeCall(Attestator.initialize, (owner, schemaRegistry, eas)))
            )
        );

        // Set the approved caller
        vm.startPrank(owner);
        approvedCaller = makeAddr("approvedCaller");
        attestator.setApprovedCaller(approvedCaller, true);
        vm.stopPrank();
    }

    function test_initialize() public view {
        assertEq(attestator.owner(), owner);
        assertEq(address(attestator.schemaRegistry()), schemaRegistry);
        assertEq(address(attestator.eas()), eas);
    }

    function test_initialize_revert_ZeroSchemaRegistry() public {
        address attestatorImpl = address(new Attestator());
        vm.expectRevert(Errors.Attestator__ZeroSchemaRegistry.selector);
        new ERC1967Proxy(attestatorImpl, abi.encodeCall(Attestator.initialize, (owner, address(0), address(1))));
    }

    function test_initialize_revert_ZeroEAS() public {
        address attestatorImpl = address(new Attestator());
        vm.expectRevert(Errors.Attestator__ZeroEAS.selector);
        new ERC1967Proxy(attestatorImpl, abi.encodeCall(Attestator.initialize, (owner, address(1), address(0))));
    }

    function test_setSchemaRegistry_revert_NotOwner() public {
        vm.startPrank(address(2));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(2)));
        attestator.setSchemaRegistry(address(1));
        vm.stopPrank();
    }

    function test_setSchemaRegistry_revert_ZeroSchemaRegistry() public {
        vm.expectRevert(Errors.Attestator__ZeroSchemaRegistry.selector);
        vm.startPrank(owner);
        attestator.setSchemaRegistry(address(0));
        vm.stopPrank();
    }

    function test_setSchemaRegistry() public {
        vm.startPrank(owner);
        attestator.setSchemaRegistry(address(1));
        assertEq(address(attestator.schemaRegistry()), address(1));
        vm.stopPrank();
    }

    function test_setEAS_revert_NotOwner() public {
        vm.startPrank(address(2));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(2)));
        attestator.setEAS(address(1));
        vm.stopPrank();
    }

    function test_setEAS_revert_ZeroEAS() public {
        vm.expectRevert(Errors.Attestator__ZeroEAS.selector);
        vm.startPrank(owner);
        attestator.setEAS(address(0));
        vm.stopPrank();
    }

    function test_setEAS() public {
        vm.startPrank(owner);
        attestator.setEAS(address(1));
        assertEq(address(attestator.eas()), address(1));
        vm.stopPrank();
    }

    function test_setApprovedCaller_revert_NotOwner() public {
        vm.startPrank(address(2));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(2)));
        attestator.setApprovedCaller(address(1), true);
        vm.stopPrank();
    }

    function test_setApprovedCaller_revert_ZeroCaller() public {
        vm.expectRevert(Errors.Attestator__ZeroCaller.selector);
        vm.startPrank(owner);
        attestator.setApprovedCaller(address(0), true);
        vm.stopPrank();
    }

    function test_setApprovedCaller() public {
        vm.startPrank(owner);
        attestator.setApprovedCaller(address(1), true);
        assertEq(attestator.approvedCallers(address(1)), true);
        vm.stopPrank();
    }

    function test_multiAttest_revert_NotApprovedCaller() public {
        vm.startPrank(address(1));
        vm.expectRevert(Errors.Attestator__NotApprovedCaller.selector);
        attestator.multiAttest(new MultiAttestationRequest[](0));
        vm.stopPrank();
    }

    function test_multiAttest() public {
        AttestationRequestData[] memory requestData = new AttestationRequestData[](1);
        requestData[0] = AttestationRequestData(
            address(0xb5f173bF43F4Fd0D7fE80243d74Ce011F35ECFCB), 0, true, bytes32(0), bytes("test"), 0
        );

        MultiAttestationRequest[] memory multiRequests = new MultiAttestationRequest[](1);
        multiRequests[0] = MultiAttestationRequest(
            bytes32(0x9f898eca4ae41fb754e11c0062de5a4c6f35b52baa22df17bffa20a0d9fad28e), requestData
        );

        vm.startPrank(approvedCaller);
        attestator.multiAttest(multiRequests);
        vm.stopPrank();
    }

    function test_multiRevoke_revert_NotApprovedCaller() public {
        vm.startPrank(address(1));
        vm.expectRevert(Errors.Attestator__NotApprovedCaller.selector);
        attestator.multiRevoke(new MultiRevocationRequest[](0));
        vm.stopPrank();
    }

    function test_multiRevoke() public {
        AttestationRequestData[] memory requestData = new AttestationRequestData[](1);
        requestData[0] = AttestationRequestData(
            address(0xb5f173bF43F4Fd0D7fE80243d74Ce011F35ECFCB), 0, true, bytes32(0), bytes("test"), 0
        );

        MultiAttestationRequest[] memory multiRequests = new MultiAttestationRequest[](1);
        multiRequests[0] = MultiAttestationRequest(
            bytes32(0x9f898eca4ae41fb754e11c0062de5a4c6f35b52baa22df17bffa20a0d9fad28e), requestData
        );

        vm.startPrank(approvedCaller);
        bytes32[] memory uids = attestator.multiAttest(multiRequests);
        vm.stopPrank();

        RevocationRequestData[] memory revocationRequestData = new RevocationRequestData[](1);
        revocationRequestData[0] = RevocationRequestData(uids[0], 0);

        MultiRevocationRequest[] memory multiRevokes = new MultiRevocationRequest[](1);
        multiRevokes[0] = MultiRevocationRequest(
            bytes32(0x9f898eca4ae41fb754e11c0062de5a4c6f35b52baa22df17bffa20a0d9fad28e), revocationRequestData
        );

        vm.startPrank(approvedCaller);
        attestator.multiRevoke(multiRevokes);
        vm.stopPrank();
    }

    function test_registerSchema_revert_NotApprovedCaller() public {
        vm.startPrank(address(1));
        vm.expectRevert(Errors.Attestator__NotApprovedCaller.selector);
        attestator.registerSchema("test", ISchemaResolver(address(0)), true);
        vm.stopPrank();
    }

    function test_registerSchema() public {
        vm.startPrank(approvedCaller);
        string memory schema = "test";
        ISchemaResolver resolver = ISchemaResolver(address(0));
        attestator.registerSchema(schema, resolver, true);
        vm.stopPrank();
    }

    function test_upgrade() public {
        address easAddressBefore = address(attestator.eas());
        address schemaRegistryAddressBefore = address(attestator.schemaRegistry());

        vm.startPrank(owner);
        address newAttestatorImpl = address(new Attestator());
        UUPSUpgradeable(address(attestator)).upgradeToAndCall(newAttestatorImpl, "");
        vm.stopPrank();

        address easAddressAfter = address(attestator.eas());
        address schemaRegistryAddressAfter = address(attestator.schemaRegistry());

        assertEq(easAddressAfter, easAddressBefore);
        assertEq(schemaRegistryAddressAfter, schemaRegistryAddressBefore);
    }
}
