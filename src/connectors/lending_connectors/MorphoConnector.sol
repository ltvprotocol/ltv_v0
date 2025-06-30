// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../interfaces/ILendingConnector.sol";
import "./interfaces/IMorphoBlue.sol";
import "../../utils/MulDiv.sol";

contract MorphoConnector is ILendingConnector {
    using uMulDiv for uint128;

    IMorphoBlue public constant MORPHO = IMorphoBlue(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);

    // bytes32(uint256(keccak256("ltv.storage.MorphoConnector")) - 1)
    bytes32 private constant MorhpConnectorStorageLocation =
        0x3ce092b68bc5f5a93dae5498ed388a510f95f75f908bb65f889a019a5a7397e4;

    struct MorphoConnectorStorage {
        IMorphoBlue.MarketParams marketParams;
        bytes32 marketId;
    }

    function _getMorphoConnectorStorage() private pure returns (MorphoConnectorStorage storage s) {
        assembly {
            s.slot := MorhpConnectorStorageLocation
        }
    }

    function supply(uint256 amount) external {
        MorphoConnectorStorage storage s = _getMorphoConnectorStorage();
        IERC20(s.marketParams.collateralToken).approve(address(MORPHO), amount);
        MORPHO.supplyCollateral(s.marketParams, amount, address(this), "");
    }

    function withdraw(uint256 amount) external {
        MORPHO.withdrawCollateral(_getMorphoConnectorStorage().marketParams, amount, address(this), address(this));
    }

    function borrow(uint256 amount) external {
        MORPHO.borrow(_getMorphoConnectorStorage().marketParams, amount, 0, address(this), address(this));
    }

    function repay(uint256 amount) external {
        MorphoConnectorStorage storage s = _getMorphoConnectorStorage();
        IERC20(s.marketParams.loanToken).approve(address(MORPHO), amount);
        MORPHO.repay(s.marketParams, amount, 0, address(this), "");
    }

    function getRealCollateralAssets(bool) external view returns (uint256) {
        (,, uint128 collateral) = MORPHO.position(_getMorphoConnectorStorage().marketId, msg.sender);
        return collateral;
    }

    function getRealBorrowAssets(bool isDeposit) external view returns (uint256) {
        MorphoConnectorStorage storage s = _getMorphoConnectorStorage();
        (, uint128 borrowShares,) = MORPHO.position(s.marketId, msg.sender);
        if (borrowShares == 0) return 0;

        (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) = MORPHO.market(s.marketId);
        if (totalBorrowShares == 0) return 0;

        return borrowShares.mulDiv(totalBorrowAssets, totalBorrowShares, isDeposit);
    }

    function getRealCollateralTokenAmount() external view returns (uint256) {
        (,, uint256 collateral) = MORPHO.position(_getMorphoConnectorStorage().marketId, address(this));
        return collateral;
    }
}
