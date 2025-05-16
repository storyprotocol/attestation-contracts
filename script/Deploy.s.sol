// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {Attestator} from "contracts/Attestator.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Mainnet deployment
// forge script script/Deploy.s.sol:Deploy --rpc-url ${STORY_RPC_MAINNET} --broadcast --sender ${SENDER_ADDRESS_MAINNET} --priority-gas-price 1 --legacy --verify --verifier=blockscout --verifier-url ${VERIFIER_URL_MAINNET} --private-key ${SENDER_PRIVATE_KEY_MAINNET} --sig "run(address)" ${ADMIN_ADDRESS_MAINNET}

// Aeneid deployment
// forge script script/Deploy.s.sol:Deploy --rpc-url ${STORY_RPC_AENEID} --broadcast --sender ${SENDER_ADDRESS_AENEID} --priority-gas-price 1 --legacy --verify --verifier=blockscout --verifier-url ${VERIFIER_URL_AENEID} --private-key ${SENDER_PRIVATE_KEY_AENEID} --sig "run(address)" ${ADMIN_ADDRESS_AENEID}

contract Deploy is Script {
    address public constant EAS_MAINNET = 0x5bF79CECE7D1C9DA45a9F0dE480589ecCE1B48c8;
    address public constant EAS_AENEID = 0xDcd40C896274E7e9776A48deB0fA34999935Ee55;
    address public constant SCHEMA_REGISTRY_MAINNET = 0x5F983ab12EE78535C9067dE1CDFc7C511320fB7d;
    address public constant SCHEMA_REGISTRY_AENEID = 0x2a3565551548abfcdeB9983230D9CAcBb8c6c16c;

    function run(address owner) public {
        vm.startBroadcast();

        uint256 chainId = block.chainid;
        if (chainId != 1315 && chainId != 1514) revert("Invalid chain id");
        if (owner == address(0)) revert("Zero owner");

        address eas = chainId == 1514 ? EAS_MAINNET : EAS_AENEID;
        address schemaRegistry = chainId == 1514 ? SCHEMA_REGISTRY_MAINNET : SCHEMA_REGISTRY_AENEID;

        address attestator = address(new Attestator());
        address proxy =
            address(new ERC1967Proxy(attestator, abi.encodeCall(Attestator.initialize, (owner, schemaRegistry, eas))));

        console2.log("Attestator implementation deployed at", attestator);
        console2.log("Attestator proxy deployed at", proxy);

        vm.stopBroadcast();
    }
}
