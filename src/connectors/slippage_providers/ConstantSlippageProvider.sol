// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ISlippageProvider} from "src/interfaces/ISlippageProvider.sol";
import {LTVState} from "src/states/LTVState.sol";

contract ConstantSlippageProvider is LTVState, ISlippageProvider {
    function collateralSlippage(bytes calldata slippageProviderGetterData) external pure returns (uint256) {
        (uint256 collateralSlippageValue,) = abi.decode(slippageProviderGetterData, (uint256, uint256));
        return collateralSlippageValue;
    }

    function borrowSlippage(bytes calldata slippageProviderGetterData) external pure returns (uint256) {
        (, uint256 borrowSlippageValue) = abi.decode(slippageProviderGetterData, (uint256, uint256));
        return borrowSlippageValue;
    }

    function initializeSlippageProviderData(bytes calldata slippageProviderData) external {
        slippageProviderGetterData = slippageProviderData;
    }
}
