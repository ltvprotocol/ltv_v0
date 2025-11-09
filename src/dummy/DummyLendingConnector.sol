// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILendingConnector} from "../interfaces/connectors/ILendingConnector.sol";
import {IDummyLending} from "./interfaces/IDummyLending.sol";

contract DummyLendingConnector is ILendingConnector {
    using SafeERC20 for IERC20;

    IERC20 public immutable COLLATERAL_TOKEN;
    IERC20 public immutable BORROW_TOKEN;
    IDummyLending public immutable LENDING_PROTOCOL;

    constructor(IERC20 _collateralToken, IERC20 _borrowToken, IDummyLending _lendingProtocol) {
        COLLATERAL_TOKEN = _collateralToken;
        BORROW_TOKEN = _borrowToken;
        LENDING_PROTOCOL = _lendingProtocol;
    }

    function supply(uint256 assets) external override {
        COLLATERAL_TOKEN.forceApprove(address(LENDING_PROTOCOL), assets);
        LENDING_PROTOCOL.supply(address(COLLATERAL_TOKEN), assets);
    }

    function withdraw(uint256 assets) external override {
        LENDING_PROTOCOL.withdraw(address(COLLATERAL_TOKEN), assets);
    }

    function borrow(uint256 assets) external override {
        LENDING_PROTOCOL.borrow(address(BORROW_TOKEN), assets);
    }

    function repay(uint256 assets) external override {
        BORROW_TOKEN.forceApprove(address(LENDING_PROTOCOL), assets);
        LENDING_PROTOCOL.repay(address(BORROW_TOKEN), assets);
    }

    function getRealBorrowAssets(bool, bytes calldata) external view override returns (uint256) {
        return LENDING_PROTOCOL.borrowBalance(address(BORROW_TOKEN));
    }

    function getRealCollateralAssets(bool, bytes calldata) external view override returns (uint256) {
        return LENDING_PROTOCOL.supplyBalance(address(COLLATERAL_TOKEN));
    }

    function initializeLendingConnectorData(bytes memory) external pure {}
}
