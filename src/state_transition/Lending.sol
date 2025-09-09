// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "../interfaces/connectors/ILendingConnector.sol";
import {RevertWithDataIfNeeded} from "../utils/RevertWithDataIfNeeded.sol";
import {GetLendingConnector} from "../public/administration/read/GetLendingConnector.sol";
import {GetLendingConnectorStateReader} from "../state_reader/administration/GetLendingConnectorStateReader.sol";

abstract contract Lending is GetLendingConnectorStateReader, GetLendingConnector, RevertWithDataIfNeeded {
    function borrow(uint256 assets) internal {
        (bool isSuccess, bytes memory data) = address(getLendingConnector(getLendingConnectorState())).delegatecall(
            abi.encodeCall(ILendingConnector.borrow, (assets))
        );
        revertWithDataIfNeeded(isSuccess, data);
    }

    function repay(uint256 assets) internal {
        (bool isSuccess, bytes memory data) = address(getLendingConnector(getLendingConnectorState())).delegatecall(
            abi.encodeCall(ILendingConnector.repay, (assets))
        );
        revertWithDataIfNeeded(isSuccess, data);
    }

    function supply(uint256 assets) internal {
        (bool isSuccess, bytes memory data) = address(getLendingConnector(getLendingConnectorState())).delegatecall(
            abi.encodeCall(ILendingConnector.supply, (assets))
        );
        revertWithDataIfNeeded(isSuccess, data);
    }

    function withdraw(uint256 assets) internal {
        (bool isSuccess, bytes memory data) = address(getLendingConnector(getLendingConnectorState())).delegatecall(
            abi.encodeCall(ILendingConnector.withdraw, (assets))
        );
        revertWithDataIfNeeded(isSuccess, data);
    }
}
