// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ISlippageConnector} from "src/interfaces/ISlippageConnector.sol";
import {LTVState} from "src/states/LTVState.sol";

contract ConstantSlippageConnector is LTVState, ISlippageConnector {
    function collateralSlippage(bytes calldata slippageConnectorGetterData) external pure returns (uint256) {
        (uint256 collateralSlippageValue,) = abi.decode(slippageConnectorGetterData, (uint256, uint256));
        return collateralSlippageValue;
    }

    function borrowSlippage(bytes calldata slippageConnectorGetterData) external pure returns (uint256) {
        (, uint256 borrowSlippageValue) = abi.decode(slippageConnectorGetterData, (uint256, uint256));
        return borrowSlippageValue;
    }

    function initializeSlippageConnectorData(bytes calldata slippageConnectorData) external {
        slippageConnectorGetterData = slippageConnectorData;
    }
}
