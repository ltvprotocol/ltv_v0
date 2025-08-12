// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "../../interfaces/ILendingConnector.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../hodlmybeer/IHodlMyBeerLending.sol";
import "../spooky/ISpookyOracle.sol";

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

    function initializeProtocol(bytes memory) external pure {}
}
