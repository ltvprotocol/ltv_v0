// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../utils/BaseScript.s.sol";
import "../../src/connectors/slippage_providers/ConstantSlippageProvider.sol";

contract DeployConstantSlippageConnector is BaseScript {
    function deploy() internal override {
        uint256 collateralSlippage = vm.envUint("COLLATERAL_SLIPPAGE");
        uint256 borrowSlippage = vm.envUint("BORROW_SLIPPAGE");
        address initialOwner = vm.envAddress("SLIPPAGE_PROVIDER_OWNER");

        ConstantSlippageProvider slippageProvider =
            new ConstantSlippageProvider{salt: bytes32(0)}(collateralSlippage, borrowSlippage, initialOwner);

        console.log("ConstantSlippageProvider deployed at: ", address(slippageProvider));
    }

    function hashedCreationCode() internal view override returns (bytes32) {
        uint256 collateralSlippage = vm.envUint("COLLATERAL_SLIPPAGE");
        uint256 borrowSlippage = vm.envUint("BORROW_SLIPPAGE");
        address initialOwner = vm.envAddress("SLIPPAGE_PROVIDER_OWNER");

        return keccak256(abi.encodePacked(type(ConstantSlippageProvider).creationCode, abi.encode(collateralSlippage, borrowSlippage, initialOwner)));
    }
}
