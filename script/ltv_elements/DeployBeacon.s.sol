// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {console} from "forge-std/console.sol";

contract DeployBeacon is BaseScript {
    function deploy() internal override {
        address beaconOwner = vm.envAddress("BEACON_OWNER");
        address ltv = vm.envAddress("LTV");
        address beacon = vm.envOr("BEACON", address(0));
        if (beacon != address(0)) {
            console.log("Beacon already deployed at: ", beacon);
            return;
        }

        require(vm.envBool("DEPLOY_BEACON"), "Need to specify manualy that beacon has to be deployed");
        beacon = address(new UpgradeableBeacon{salt: bytes32(0)}(ltv, beaconOwner));
        console.log("Beacon deployed at: ", beacon);
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address beaconOwner = vm.envAddress("BEACON_OWNER");
        address ltv = vm.envAddress("LTV");
        return keccak256(abi.encodePacked(type(UpgradeableBeacon).creationCode, abi.encode(ltv, beaconOwner)));
    }

    function expectedAddress(bytes32 _hashedCreationCode) internal view override returns (address) {
        address beacon = vm.envOr("BEACON", address(0));
        if (beacon != address(0)) {
            return beacon;
        }
        return super.expectedAddress(_hashedCreationCode);
    }
}
