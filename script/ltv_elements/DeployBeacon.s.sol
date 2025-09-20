// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {BaseScript} from "../utils/BaseScript.s.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {console} from "forge-std/console.sol";

contract DeployBeacon is BaseScript {
    function deploy() internal override {
        address beaconOwner = vm.envAddress("BEACON_OWNER");
        address ltv = vm.envAddress("LTV");
        UpgradeableBeacon beacon = new UpgradeableBeacon{salt: bytes32(0)}(ltv, beaconOwner);
        console.log("Beacon deployed at: ", address(beacon));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        address beaconOwner = vm.envAddress("BEACON_OWNER");
        address ltv = vm.envAddress("LTV");
        return keccak256(abi.encodePacked(type(UpgradeableBeacon).creationCode, abi.encode(ltv, beaconOwner)));
    }
}
