// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IBeacon} from "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";
import {Proxy} from "openzeppelin-contracts/contracts/proxy/Proxy.sol";
import {ERC1967Utils} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {BeaconProxyAdmin} from "./BeaconProxyAdmin.sol";
import {IERC1967} from "openzeppelin-contracts/contracts/interfaces/IERC1967.sol";

interface ITransparentUpgradeableBeaconProxy is IERC1967 {
    function upgradeBeaconToAndCall(address newImplementation, bytes calldata data) external payable;
}

contract TransparentUpgradeableBeaconProxy is Proxy {
    address private immutable ADMIN;

    error ProxyDeniedAdminAccess();

    constructor(address beacon, address initialOwner, bytes memory data) payable {
        ERC1967Utils.upgradeBeaconToAndCall(beacon, data);

        ADMIN = address(new BeaconProxyAdmin(initialOwner));
        ERC1967Utils.changeAdmin(ADMIN);
    }

    function _implementation() internal view override returns (address) {
        return IBeacon(ERC1967Utils.getBeacon()).implementation();
    }

    function _fallback() internal virtual override {
        if (msg.sender == ADMIN) {
            if (msg.sig != ITransparentUpgradeableBeaconProxy.upgradeBeaconToAndCall.selector) {
                revert ProxyDeniedAdminAccess();
            } else {
                _dispatchUpgradeBeaconToAndCall();
            }
        } else {
            super._fallback();
        }
    }

    function _dispatchUpgradeBeaconToAndCall() private {
        (address newBeacon, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
        ERC1967Utils.upgradeBeaconToAndCall(newBeacon, data);
    }
}
