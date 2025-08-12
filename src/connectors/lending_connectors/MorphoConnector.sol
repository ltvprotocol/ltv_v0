// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../interfaces/ILendingConnector.sol";
import "./interfaces/IMorphoBlue.sol";
import "../../utils/MulDiv.sol";
import {LTVState} from "../../states/LTVState.sol";

contract MorphoConnector is LTVState, ILendingConnector {
    using uMulDiv for uint128;

    IMorphoBlue public constant MORPHO = IMorphoBlue(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);

    // bytes32(uint256(keccak256("ltv.storage.MorphoConnector")) - 1)
    bytes32 private constant MorhpConnectorStorageLocation =
        0x3ce092b68bc5f5a93dae5498ed388a510f95f75f908bb65f889a019a5a7397e4;

    struct MorphoConnectorStorage {
        address oracle;
        address irm;
        uint256 lltv;
        bytes32 marketId;
    }

    function _getMorphoConnectorStorage() private pure returns (MorphoConnectorStorage storage s) {
        assembly {
            s.slot := MorhpConnectorStorageLocation
        }
    }

    function _createMarketParams() private view returns (IMorphoBlue.MarketParams memory) {
        MorphoConnectorStorage storage s = _getMorphoConnectorStorage();
        return IMorphoBlue.MarketParams({
            loanToken: address(borrowToken),
            collateralToken: address(collateralToken),
            oracle: s.oracle,
            irm: s.irm,
            lltv: s.lltv
        });
    }

    function supply(uint256 amount) external {
        collateralToken.approve(address(MORPHO), amount);
        MORPHO.supplyCollateral(_createMarketParams(), amount, address(this), "");
    }

    function withdraw(uint256 amount) external {
        MORPHO.withdrawCollateral(_createMarketParams(), amount, address(this), address(this));
    }

    function borrow(uint256 amount) external {
        MORPHO.borrow(_createMarketParams(), amount, 0, address(this), address(this));
    }

    function repay(uint256 amount) external {
        borrowToken.approve(address(MORPHO), amount);
        MORPHO.repay(_createMarketParams(), amount, 0, address(this), "");
    }

    function getRealCollateralAssets(bool, bytes calldata marketIdData) external view returns (uint256) {
        bytes32 marketId = abi.decode(marketIdData, (bytes32));
        (,, uint128 collateral) = MORPHO.position(marketId, msg.sender);
        return collateral;
    }

    function getRealBorrowAssets(bool isDeposit, bytes calldata marketIdData) external view returns (uint256) {
        bytes32 marketId = abi.decode(marketIdData, (bytes32));

        (, uint128 borrowShares,) = MORPHO.position(marketId, msg.sender);
        if (borrowShares == 0) return 0;

        (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) = MORPHO.market(marketId);
        if (totalBorrowShares == 0) return 0;

        return borrowShares.mulDiv(totalBorrowAssets, totalBorrowShares, isDeposit);
    }

    function initializeLendingConnectorData(bytes memory data) external {
        (address oracle, address irm, uint256 lltv, bytes32 marketId) =
            abi.decode(data, (address, address, uint256, bytes32));

        MorphoConnectorStorage storage s = _getMorphoConnectorStorage();
        s.oracle = oracle;
        s.irm = irm;
        s.lltv = lltv;
        s.marketId = marketId;

        lendingConnectorGetterData = abi.encode(marketId);
    }
}
