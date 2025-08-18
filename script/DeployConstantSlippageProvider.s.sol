// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ConstantSlippageProvider} from "src/connectors/slippage_providers/ConstantSlippageProvider.sol";

contract DeployConstantSlippageProvider is Script {
    function run() external {
        address initialOwner = vm.envAddress("SLIPPAGE_PROVIDER_OWNER");
        uint256 collateralSlippage = vm.envUint("COLLATERAL_SLIPPAGE");
        uint256 borrowSlippage = vm.envUint("BORROW_SLIPPAGE");

        vm.startBroadcast();

        ConstantSlippageProvider slippageProvider =
            new ConstantSlippageProvider(collateralSlippage, borrowSlippage, initialOwner);

        console.log("ConstantSlippageProvider deployed at: ", address(slippageProvider));

        vm.stopBroadcast();
    }
}
