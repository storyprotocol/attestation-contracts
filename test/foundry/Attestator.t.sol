// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {ISchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/ISchemaResolver.sol";
import {MultiAttestationRequest, AttestationRequestData} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

import {Attestator} from "../../contracts/Attestator.sol";
import {Errors} from "../../contracts/lib/Errors.sol";

contract AttestatorTest is Test {
    Attestator public attestator;
    address public owner;
    address public approvedCaller;

    function setUp() public {
        // Fork the desired network where EAS contracts are deployed
        uint256 forkId = vm.createFork("https://mainnet.storyrpc.io/");
        vm.selectFork(forkId);

        // Mainnet
        // EAS related addresses
        address eas = 0x5bF79CECE7D1C9DA45a9F0dE480589ecCE1B48c8;
        address schemaRegistry = 0x5F983ab12EE78535C9067dE1CDFc7C511320fB7d;

        // Deploy the Attestator contract
        owner = makeAddr("owner");
        attestator = new Attestator(owner, schemaRegistry, eas);

        // Set the approved caller
        vm.startPrank(owner);
        approvedCaller = makeAddr("approvedCaller");
        attestator.setApprovedCaller(approvedCaller, true);
        vm.stopPrank();
    }

    function test_constructor_revert_ZeroSchemaRegistry() public {
        vm.expectRevert(Errors.Attestator__ZeroSchemaRegistry.selector);
        new Attestator(address(1), address(0), address(2));
    }

    function test_constructor_revert_ZeroEAS() public {
        vm.expectRevert(Errors.Attestator__ZeroEAS.selector);
        new Attestator(address(1), address(2), address(0));
    }

    function test_constructor() public {
        Attestator newAttestator = new Attestator(address(1), address(2), address(3));
        assertEq(newAttestator.owner(), address(1));
        assertEq(address(newAttestator.schemaRegistry()), address(2));
        assertEq(address(newAttestator.eas()), address(3));
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

    function test_registerSchema() public {
        vm.startPrank(approvedCaller);
        string memory schema = "test";
        ISchemaResolver resolver = ISchemaResolver(address(0));
        attestator.registerSchema(schema, resolver, true);
        vm.stopPrank();
    }
}
