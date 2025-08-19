// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {IHodlMyBeerLending} from "src/ghost/hodlmybeer/IHodlMyBeerLending.sol";

contract HodlLendingConnector is ILendingConnector {
    IHodlMyBeerLending public immutable LENDING_PROTOCOL;

    IERC20 public immutable COLLATERAL_TOKEN;
    IERC20 public immutable BORROW_TOKEN;

    constructor(IERC20 _collateralToken, IERC20 _borrowToken, IHodlMyBeerLending _lendingProtocol) {
        COLLATERAL_TOKEN = _collateralToken;
        BORROW_TOKEN = _borrowToken;
        LENDING_PROTOCOL = _lendingProtocol;
    }

    function supply(uint256 assets) external {
        COLLATERAL_TOKEN.approve(address(LENDING_PROTOCOL), assets);
        LENDING_PROTOCOL.supplyCollateral(assets);
    }

    function withdraw(uint256 assets) external {
        LENDING_PROTOCOL.withdrawCollateral(assets);
    }

    function borrow(uint256 assets) external {
        LENDING_PROTOCOL.borrow(assets);
    }

    function repay(uint256 assets) external {
        BORROW_TOKEN.approve(address(LENDING_PROTOCOL), assets);
        LENDING_PROTOCOL.repay(assets);
    }

    function getRealBorrowAssets(bool, bytes calldata) external view returns (uint256) {
        return LENDING_PROTOCOL.borrowBalance(msg.sender);
    }

    function getRealCollateralAssets(bool, bytes calldata) external view returns (uint256) {
        return LENDING_PROTOCOL.supplyCollateralBalance(msg.sender);
    }

    function initializeProtocol(bytes memory) external pure {}
}
