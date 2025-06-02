// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "../../interfaces/ILendingConnector.sol";
import "./interfaces/IMorphoBlue.sol";
import "src/utils/MulDiv.sol";

contract MorphoConnector is ILendingConnector {
    using uMulDiv for uint128;

    IMorphoBlue public constant MORPHO = IMorphoBlue(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);
    IMorphoBlue.MarketParams public marketParams;
    bytes32 public immutable marketId;

    constructor(IMorphoBlue.MarketParams memory _marketParams) {
        marketParams = _marketParams;
        marketId = keccak256(abi.encode(marketParams));
    }

    function borrow(uint256 amount) external {
        MORPHO.borrow(marketParams, amount, 0, address(this), address(this));
    }

    function repay(uint256 amount) external {
        MORPHO.repay(marketParams, amount, 0, address(this), "");
    }

    function supply(uint256 amount) external {
        MORPHO.supply(marketParams, amount, 0, address(this), "");
    }

    function withdraw(uint256 amount) external {
        MORPHO.withdraw(marketParams, amount, 0, address(this), address(this));
    }

    function getRealCollateralAssets(bool isDeposit) external view returns (uint256) {
        (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) = MORPHO.market(marketId);
        (uint128 supplyShares,,) = MORPHO.position(marketId, address(this));
        return totalSupplyAssets.mulDiv(supplyShares, totalSupplyShares, isDeposit);
    }

    function getRealBorrowAssets(bool isDeposit) external view returns (uint256) {
        (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) = MORPHO.market(marketId);
        (, uint128 borrowShares,) = MORPHO.position(marketId, address(this));
        return totalBorrowAssets.mulDiv(borrowShares, totalBorrowShares, isDeposit);
    }
}
