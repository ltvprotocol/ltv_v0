// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {IHodlMyBeerLending} from "src/ghost/hodlmybeer/IHodlMyBeerLending.sol";
import {LTVState} from "../../states/LTVState.sol";

contract HodlLendingConnector is LTVState, ILendingConnector {
    IHodlMyBeerLending public immutable LENDING_PROTOCOL;

    constructor(IHodlMyBeerLending _lendingProtocol) {
        LENDING_PROTOCOL = _lendingProtocol;
    }

    function supply(uint256 assets) external {
        collateralToken.approve(address(LENDING_PROTOCOL), assets);
        LENDING_PROTOCOL.supplyCollateral(assets);
    }

    function withdraw(uint256 assets) external {
        LENDING_PROTOCOL.withdrawCollateral(assets);
    }

    function borrow(uint256 assets) external {
        LENDING_PROTOCOL.borrow(assets);
    }

    function repay(uint256 assets) external {
        borrowToken.approve(address(LENDING_PROTOCOL), assets);
        LENDING_PROTOCOL.repay(assets);
    }

    function getRealBorrowAssets(bool, bytes calldata) external view returns (uint256) {
        return LENDING_PROTOCOL.borrowBalance(msg.sender);
    }

    function getRealCollateralAssets(bool, bytes calldata) external view returns (uint256) {
        return LENDING_PROTOCOL.supplyCollateralBalance(msg.sender);
    }

    function initializeLendingConnectorData(bytes memory) external pure {}
}
