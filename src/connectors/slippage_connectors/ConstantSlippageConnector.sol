// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ISlippageConnector} from "src/interfaces/connectors/ISlippageConnector.sol";
import {LTVState} from "src/states/LTVState.sol";
import {Constants} from "src/constants/Constants.sol";
import {IConstantSlippageConnectorErrors} from "src/errors/connectors/IConstantSlippageConnectorErrors.sol";

/**
 * @title ConstantSlippageConnector
 * @notice Constant slippage Connector for LTV protocol
 * @dev It stores constant slippages values in the LTV protocol storage and retrieves it when needed.
 */
contract ConstantSlippageConnector is LTVState, ISlippageConnector, IConstantSlippageConnectorErrors {
    /**
     * @inheritdoc ISlippageConnector
     */
    function collateralSlippage(bytes calldata slippageConnectorGetterData) external pure returns (uint256) {
        (uint256 collateralSlippageValue,) = abi.decode(slippageConnectorGetterData, (uint256, uint256));
        return collateralSlippageValue;
    }

    /**
     * @inheritdoc ISlippageConnector
     */
    function borrowSlippage(bytes calldata slippageConnectorGetterData) external pure returns (uint256) {
        (, uint256 borrowSlippageValue) = abi.decode(slippageConnectorGetterData, (uint256, uint256));
        return borrowSlippageValue;
    }

    /**
     * @inheritdoc ISlippageConnector
     */
    function initializeSlippageConnectorData(bytes calldata slippageConnectorData) external virtual {
        slippageConnectorGetterData = slippageConnectorData;
        (uint256 collateralSlippageValue, uint256 borrowSlippageValue) =
            abi.decode(slippageConnectorData, (uint256, uint256));
        require(
            collateralSlippageValue != 0 && collateralSlippageValue < uint256(Constants.SLIPPAGE_PRECISION),
            InvalidCollateralSlippageValue()
        );
        require(
            borrowSlippageValue != 0 && borrowSlippageValue < uint256(Constants.SLIPPAGE_PRECISION),
            InvalidBorrowSlippageValue()
        );
    }
}
