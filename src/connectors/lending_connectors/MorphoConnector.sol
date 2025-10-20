// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {ILendingConnector} from "src/interfaces/connectors/ILendingConnector.sol";
import {MorphoConnectorStorage} from "src/structs/connectors/MorphoConnectorStorage.sol";
import {IMorphoBlue} from "src/connectors/lending_connectors/interfaces/IMorphoBlue.sol";
import {LTVState} from "src/states/LTVState.sol";
import {UMulDiv} from "src/math/libraries/MulDiv.sol";

/**
 * @title MorphoConnector
 * @notice Connector for Morpho protocol
 */
contract MorphoConnector is LTVState, ILendingConnector {
    using UMulDiv for uint128;

    /**
     * @notice Error thrown when morpho address is zero
     */
    error ZeroMorphoAddress();

    /**
     * @notice Error thrown when LLTv market param is zero
     */
    error ZeroLltvMarketParam();
    /**
     * @notice Error thrown when oracle market param is zero
     */
    error ZeroOracleMarketParam();
    /**
     * @notice Error thrown when IRM market param is zero
     */
    error ZeroIrmMarketParam();

    /**
     * @notice Error thrown when provided oracle address doesn't correspond
     * to provided marketId
     */
    error InvalidOracle(address provided, address fetched);
    /**
     * @notice Error thrown when provided IRM address doesn't correspond
     * to provided marketId
     */
    error InvalidIrm(address provided, address fetched);
    /**
     * @notice Error thrown when provided lltv doesn't correspond
     * to marketId
     */
    error InvalidLltv(uint256 provided, uint256 fetched);

    IMorphoBlue public immutable MORPHO;

    // bytes32(uint256(keccak256("ltv.storage.MorphoConnector")) - 1)
    bytes32 private constant MORPHO_CONNECTOR_STORAGE_LOCATION =
        0x3ce092b68bc5f5a93dae5498ed388a510f95f75f908bb65f889a019a5a7397e4;

    constructor(address _morpho) {
        require(_morpho != address(0), ZeroMorphoAddress());
        MORPHO = IMorphoBlue(_morpho);
    }

    /**
     * @dev Get the Morpho connector storage
     */
    function _getMorphoConnectorStorage() private pure returns (MorphoConnectorStorage storage s) {
        assembly {
            s.slot := MORPHO_CONNECTOR_STORAGE_LOCATION
        }
    }

    /**
     * @dev Create the Morpho market params
     */
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

    /**
     * @inheritdoc ILendingConnector
     */
    function supply(uint256 amount) external {
        collateralToken.approve(address(MORPHO), amount);
        MORPHO.supplyCollateral(_createMarketParams(), amount, address(this), "");
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function withdraw(uint256 amount) external {
        MORPHO.withdrawCollateral(_createMarketParams(), amount, address(this), address(this));
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function borrow(uint256 amount) external {
        MORPHO.borrow(_createMarketParams(), amount, 0, address(this), address(this));
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function repay(uint256 amount) external {
        borrowToken.approve(address(MORPHO), amount);
        MORPHO.repay(_createMarketParams(), amount, 0, address(this), "");
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function getRealCollateralAssets(bool, bytes calldata marketIdData) external view returns (uint256) {
        bytes32 marketId = abi.decode(marketIdData, (bytes32));
        (,, uint128 collateral) = MORPHO.position(marketId, msg.sender);
        return collateral;
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function getRealBorrowAssets(bool isDeposit, bytes calldata marketIdData) external view returns (uint256) {
        bytes32 marketId = abi.decode(marketIdData, (bytes32));

        (, uint128 borrowShares,) = MORPHO.position(marketId, msg.sender);
        if (borrowShares == 0) return 0;

        (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) = MORPHO.market(marketId);
        if (totalBorrowShares == 0) return 0;

        return borrowShares.mulDiv(totalBorrowAssets, totalBorrowShares, isDeposit);
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function initializeLendingConnectorData(bytes memory data) external {
        (address oracle, address irm, uint256 lltv, bytes32 marketId) =
            abi.decode(data, (address, address, uint256, bytes32));

        (address loanToken, address collateralToken, address fetchedOracle, address fetchedIrm, uint256 fetchedLltv) =
            MORPHO.idToMarketParams(marketId);

        require(loanToken != address(0), ZeroLoanTokenMarketParam());
        require(collateralToken != address(0), ZeroCollateralTokenMarketParam());
        require(fetchedLltv > 0, ZeroLltvMarketParam());
        require(fetchedOracle == oracle, InvalidOracle(oracle, fetchedOracle));
        require(fetchedIrm == irm, InvalidIrm(irm, fetchedIrm));
        require(fetchedLltv == lltv, InvalidLltv(lltv, fetchedLltv));

        MorphoConnectorStorage storage s = _getMorphoConnectorStorage();
        s.oracle = oracle;
        s.irm = irm;
        s.lltv = lltv;

        lendingConnectorGetterData = abi.encode(marketId);
    }
}
