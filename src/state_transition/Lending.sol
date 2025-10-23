// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "../interfaces/connectors/ILendingConnector.sol";
import {DelegateCallPostCheck} from "../utils/DelegateCallPostCheck.sol";
import {GetLendingConnector} from "../public/administration/read/GetLendingConnector.sol";
import {GetLendingConnectorStateReader} from "../state_reader/administration/GetLendingConnectorStateReader.sol";

/**
 * @title Lending
 * @notice contract contains routers to delegate calls to the lending connector functions
 */
abstract contract Lending is GetLendingConnectorStateReader, GetLendingConnector, DelegateCallPostCheck {
    /**
     * @dev borrows assets from the lending protocol on behalf of the LTV protocol
     */
    function borrow(uint256 assets) internal {
        address lendingConnector = getLendingConnector(getLendingConnectorState());
        (bool isSuccess, bytes memory data) =
            lendingConnector.delegatecall(abi.encodeCall(ILendingConnector.borrow, (assets)));
        delegateCallPostCheck(lendingConnector, isSuccess, data);
    }

    /**
     * @dev repays assets to the lending protocol on behalf of the LTV protocol
     */
    function repay(uint256 assets) internal {
        address lendingConnector = getLendingConnector(getLendingConnectorState());
        (bool isSuccess, bytes memory data) =
            lendingConnector.delegatecall(abi.encodeCall(ILendingConnector.repay, (assets)));
        delegateCallPostCheck(lendingConnector, isSuccess, data);
    }

    /**
     * @dev supplies assets to the lending protocol on behalf of the LTV protocol
     */
    function supply(uint256 assets) internal {
        address lendingConnector = getLendingConnector(getLendingConnectorState());
        (bool isSuccess, bytes memory data) =
            lendingConnector.delegatecall(abi.encodeCall(ILendingConnector.supply, (assets)));
        delegateCallPostCheck(lendingConnector, isSuccess, data);
    }

    /**
     * @dev withdraws assets from the lending protocol on behalf of the LTV protocol
     */
    function withdraw(uint256 assets) internal {
        address lendingConnector = getLendingConnector(getLendingConnectorState());
        (bool isSuccess, bytes memory data) =
            lendingConnector.delegatecall(abi.encodeCall(ILendingConnector.withdraw, (assets)));
        delegateCallPostCheck(lendingConnector, isSuccess, data);
    }
}
