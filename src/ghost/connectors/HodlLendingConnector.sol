// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ILendingConnector} from "src/interfaces/ILendingConnector.sol";
import {IHodlMyBeerLending} from "src/ghost/hodlmybeer/IHodlMyBeerLending.sol";

contract HodlLendingConnector is ILendingConnector {
    IHodlMyBeerLending public immutable lendingProtocol;

    IERC20 public immutable COLLATERAL_TOKEN;
    IERC20 public immutable BORROW_TOKEN;

    constructor(IERC20 _collateralToken, IERC20 _borrowToken, IHodlMyBeerLending _lendingProtocol) {
        COLLATERAL_TOKEN = _collateralToken;
        BORROW_TOKEN = _borrowToken;
        lendingProtocol = _lendingProtocol;
    }

    function supply(uint256 assets) external {
        COLLATERAL_TOKEN.approve(address(lendingProtocol), assets);
        lendingProtocol.supplyCollateral(assets);
    }

    function withdraw(uint256 assets) external {
        lendingProtocol.withdrawCollateral(assets);
    }

    function borrow(uint256 assets) external {
        lendingProtocol.borrow(assets);
    }

    function repay(uint256 assets) external {
        BORROW_TOKEN.approve(address(lendingProtocol), assets);
        lendingProtocol.repay(assets);
    }

    function getRealBorrowAssets(bool, bytes calldata) external view returns (uint256) {
        return lendingProtocol.borrowBalance(msg.sender);
    }

    function getRealCollateralAssets(bool, bytes calldata) external view returns (uint256) {
        return lendingProtocol.supplyCollateralBalance(msg.sender);
    }

    function initializeLendingConnectorData(bytes memory) external pure {}
}
