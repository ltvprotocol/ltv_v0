// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../interfaces/ILendingConnector.sol";
import "./interfaces/IMorphoBlue.sol";
import "../../utils/MulDiv.sol";

contract MorphoConnector is ILendingConnector {
    using uMulDiv for uint128;

    IMorphoBlue public constant MORPHO = IMorphoBlue(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);

    IERC20 public immutable loanToken;
    IERC20 public immutable collateralToken;
    IMorphoBlue.MarketParams public marketParams;
    bytes32 public immutable marketId;

    constructor(IMorphoBlue.MarketParams memory _marketParams) {
        marketParams = _marketParams;
        loanToken = IERC20(_marketParams.loanToken);
        collateralToken = IERC20(_marketParams.collateralToken);
        marketId = keccak256(abi.encode(_marketParams));
    }

    function supply(uint256 amount) external {
        loanToken.transferFrom(msg.sender, address(this), amount);
        loanToken.approve(address(MORPHO), amount);
        MORPHO.supply(marketParams, amount, 0, address(this), "");
    }

    function withdraw(uint256 amount) external {
        MORPHO.withdraw(marketParams, amount, 0, address(this), msg.sender);
    }

    function borrow(uint256 amount) external {
        MORPHO.borrow(marketParams, amount, 0, address(this), msg.sender);
    }

    function supplyCollateral(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        collateralToken.approve(address(MORPHO), amount);
        MORPHO.supplyCollateral(marketParams, amount, address(this), "");
    }

    function withdrawCollateral(uint256 amount) external {
        MORPHO.withdrawCollateral(marketParams, amount, address(this), msg.sender);
    }

    function repay(uint256 amount) external {
        loanToken.transferFrom(msg.sender, address(this), amount);
        loanToken.approve(address(MORPHO), amount);
        MORPHO.repay(marketParams, amount, 0, address(this), "");
    }

    function getRealCollateralAssets(bool isDeposit) external view returns (uint256) {
        (uint128 supplyShares,,) = MORPHO.position(marketId, address(this));
        if (supplyShares == 0) return 0;
        
        (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) = MORPHO.market(marketId);
        if (totalSupplyShares == 0) return 0;
        
        return supplyShares.mulDiv(totalSupplyAssets, totalSupplyShares, isDeposit);
    }

    function getRealBorrowAssets(bool isDeposit) external view returns (uint256) {
        (,uint128 borrowShares,) = MORPHO.position(marketId, address(this));
        if (borrowShares == 0) return 0;
        
        (,,uint128 totalBorrowAssets, uint128 totalBorrowShares,,) = MORPHO.market(marketId);
        if (totalBorrowShares == 0) return 0;
        
        return borrowShares.mulDiv(totalBorrowAssets, totalBorrowShares, isDeposit);
    }
}