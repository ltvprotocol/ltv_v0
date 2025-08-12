// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../src/connectors/slippage_providers/ConstantSlippageProvider.sol";
import "forge-std/Script.sol";

contract DeployConstantSlippageProvider is Script {
    function run() external {
        vm.startBroadcast();

        ConstantSlippageProvider slippageProvider =
            new ConstantSlippageProvider();

        console.log("ConstantSlippageProvider deployed at: ", address(slippageProvider));

        vm.stopBroadcast();
    }
}
