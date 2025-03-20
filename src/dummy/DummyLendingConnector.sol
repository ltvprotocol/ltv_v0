// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '../interfaces/ILendingConnector.sol';
import 'forge-std/interfaces/IERC20.sol';
import '../dummy/interfaces/IDummyLending.sol';

contract DummyLendingConnector is ILendingConnector {

    IERC20 public immutable COLLATERAL_TOKEN;
    IERC20 public immutable BORROW_TOKEN;
    IDummyLending public immutable LENDING_PROTOCOL;

    constructor (IERC20 _collateralToken, IERC20 _borrowToken, IDummyLending _lendingProtocol) {
        COLLATERAL_TOKEN = _collateralToken;
        BORROW_TOKEN = _borrowToken;
        LENDING_PROTOCOL = _lendingProtocol;
    }

    function supply(uint256 assets) external override {
        COLLATERAL_TOKEN.approve(address(LENDING_PROTOCOL), assets);
        LENDING_PROTOCOL.supply(address(COLLATERAL_TOKEN), assets);
    }

    function withdraw(uint256 assets) external override {
        LENDING_PROTOCOL.withdraw(address(COLLATERAL_TOKEN), assets);
    }

    function borrow(uint256 assets) external override {
        LENDING_PROTOCOL.borrow(address(BORROW_TOKEN), assets);
    }

    function repay(uint256 assets) external override {
        BORROW_TOKEN.approve(address(LENDING_PROTOCOL), assets);
        LENDING_PROTOCOL.repay(address(BORROW_TOKEN), assets);
    }

    function getRealBorrowAssets() external view override returns (uint256) {
        return LENDING_PROTOCOL.borrowBalance(address(BORROW_TOKEN));
    }

    function getRealCollateralAssets() external view override returns (uint256) {
        return LENDING_PROTOCOL.supplyBalance(address(COLLATERAL_TOKEN));
    }
}