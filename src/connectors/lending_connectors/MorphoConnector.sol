// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../interfaces/ILendingConnector.sol";
import "./interfaces/IMorphoBlue.sol";
import "../../utils/MulDiv.sol";
import "forge-std/console.sol";

contract MorphoConnector is ILendingConnector {
    using uMulDiv for uint128;

    IMorphoBlue public constant MORPHO = IMorphoBlue(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);

    IERC20 public immutable loanToken;
    IERC20 public immutable collateralToken;
    address public immutable oracle;
    address public immutable irm;
    uint256 public immutable lltv;
    bytes32 public immutable marketId;

    constructor(IMorphoBlue.MarketParams memory _marketParams) {
        loanToken = IERC20(_marketParams.loanToken);
        collateralToken = IERC20(_marketParams.collateralToken);
        oracle = _marketParams.oracle;
        irm = _marketParams.irm;
        lltv = _marketParams.lltv;
        marketId = keccak256(abi.encode(_marketParams));
    }

    function createMarketParams() private view returns (IMorphoBlue.MarketParams memory) {
        return IMorphoBlue.MarketParams({
            loanToken: address(loanToken),
            collateralToken: address(collateralToken),
            oracle: oracle,
            irm: irm,
            lltv: lltv
        });
    }

    function supply(uint256 amount) external {
        collateralToken.approve(address(MORPHO), amount);
        MORPHO.supplyCollateral(createMarketParams(), amount, address(this), "");
    }

    function withdraw(uint256 amount) external {
        MORPHO.withdrawCollateral(createMarketParams(), amount, address(this), address(this));
    }

    function borrow(uint256 amount) external {
        MORPHO.borrow(createMarketParams(), amount, 0, address(this), address(this));
    }

    function repay(uint256 amount) external {
        loanToken.approve(address(MORPHO), amount);
        MORPHO.repay(createMarketParams(), amount, 0, address(this), "");
    }

    function getRealCollateralAssets(bool) external view returns (uint256) {
        (,, uint128 collateral) = MORPHO.position(marketId, msg.sender);
        return collateral;
    }

    function getRealBorrowAssets(bool isDeposit) external view returns (uint256) {
        (, uint128 borrowShares,) = MORPHO.position(marketId, msg.sender);
        if (borrowShares == 0) return 0;

        (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) = MORPHO.market(marketId);
        if (totalBorrowShares == 0) return 0;

        return borrowShares.mulDiv(totalBorrowAssets, totalBorrowShares, isDeposit);
    }

    function getRealCollateralTokenAmount() external view returns (uint256) {
        (,, uint256 collateral) = MORPHO.position(marketId, address(this));
        return collateral;
    }
}
