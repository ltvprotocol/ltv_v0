// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {GetLendingConnectorReader} from "src/state_reader/GetLendingConnectorReader.sol";
import {RevertWithDataIfNeeded} from "src/utils/RevertWithDataIfNeeded.sol";

/**
 * @title Lending
 * @notice contract contains routers to delegate calls to the lending connector functions
 */
abstract contract Lending is GetLendingConnectorReader, RevertWithDataIfNeeded {
    /**
     * @dev borrows assets from the lending protocol on behalf of the LTV protocol
     */
    function borrow(uint256 assets) internal {
        (bool isSuccess, bytes memory data) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.borrow, (assets)));
        revertWithDataIfNeeded(isSuccess, data);
    }

    /**
     * @dev repays assets to the lending protocol on behalf of the LTV protocol
     */
    function repay(uint256 assets) internal {
        (bool isSuccess, bytes memory data) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.repay, (assets)));
        revertWithDataIfNeeded(isSuccess, data);
    }

    /**
     * @dev supplies assets to the lending protocol on behalf of the LTV protocol
     */
    function supply(uint256 assets) internal {
        (bool isSuccess, bytes memory data) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.supply, (assets)));
        revertWithDataIfNeeded(isSuccess, data);
    }

    /**
     * @dev withdraws assets from the lending protocol on behalf of the LTV protocol
     */
    function withdraw(uint256 assets) internal {
        (bool isSuccess, bytes memory data) =
            address(getLendingConnector()).delegatecall(abi.encodeCall(ILendingConnector.withdraw, (assets)));
        revertWithDataIfNeeded(isSuccess, data);
    }
}
