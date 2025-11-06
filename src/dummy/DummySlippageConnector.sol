// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ConstantSlippageConnector} from "../connectors/slippage_connectors/ConstantSlippageConnector.sol";

contract DummySlippageConnector is ConstantSlippageConnector {
    function initializeSlippageConnectorData(bytes calldata _slippageConnectorData) external override {
        slippageConnectorGetterData = _slippageConnectorData;
    }
}
