// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ISlippageProvider} from "src/interfaces/ISlippageProvider.sol";
import {LTVState} from "src/states/LTVState.sol";

/**
 * @title ConstantSlippageProvider
 * @notice Constant slippage provider for LTV protocol
 * @dev It stores constant slippages values in the LTV protocol storage and retrieves it when needed.
 */
contract ConstantSlippageProvider is LTVState, ISlippageProvider {
    /**
     * @inheritdoc ISlippageProvider
     */
    function collateralSlippage(bytes calldata slippageProviderGetterData) external pure returns (uint256) {
        (uint256 collateralSlippageValue,) = abi.decode(slippageProviderGetterData, (uint256, uint256));
        return collateralSlippageValue;
    }

    /**
     * @inheritdoc ISlippageProvider
     */
    function borrowSlippage(bytes calldata slippageProviderGetterData) external pure returns (uint256) {
        (, uint256 borrowSlippageValue) = abi.decode(slippageProviderGetterData, (uint256, uint256));
        return borrowSlippageValue;
    }

    /**
     * @inheritdoc ISlippageProvider
     */
    function initializeSlippageProviderData(bytes calldata slippageProviderData) external {
        slippageProviderGetterData = slippageProviderData;
    }
}
