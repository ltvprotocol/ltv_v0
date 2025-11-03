// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ITransparentUpgradeableBeaconProxy} from "./UpgradeableBeaconProxy.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract BeaconProxyAdmin is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    function upgradeAndCall(ITransparentUpgradeableBeaconProxy proxy, address implementation, bytes memory data)
        public
        payable
        virtual
        onlyOwner
    {
        proxy.upgradeBeaconToAndCall{value: msg.value}(implementation, data);
    }
}
