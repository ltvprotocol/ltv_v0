// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ILendingConnector} from "../../interfaces/connectors/ILendingConnector.sol";
import {IAaveV3Pool} from "interfaces/IAaveV3Pool.sol";
import {LTVState} from "../../states/LTVState.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAaveV3ConnectorErrors} from "../../errors/connectors/IAaveV3ConnectorErrors.sol";

/**
 * @title AaveV3Connector
 * @notice Connector for Aave V3 Pool
 */
contract AaveV3Connector is LTVState, ILendingConnector, IAaveV3ConnectorErrors {
    using SafeERC20 for IERC20;

    IAaveV3Pool public immutable POOL;

    constructor(address _pool) {
        require(_pool != address(0), ZeroPoolAddress());
        POOL = IAaveV3Pool(_pool);
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function supply(uint256 amount) external {
        collateralToken.forceApprove(address(POOL), amount);
        POOL.supply(address(collateralToken), amount, address(this), 0);
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function withdraw(uint256 amount) external {
        POOL.withdraw(address(collateralToken), amount, address(this));
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function borrow(uint256 amount) external {
        POOL.borrow(address(borrowToken), amount, 2, 0, address(this));
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function repay(uint256 amount) external {
        borrowToken.forceApprove(address(POOL), amount);
        POOL.repay(address(borrowToken), amount, 2, address(this));
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function getRealCollateralAssets(bool, bytes calldata data) external view returns (uint256) {
        (address collateralAToken,) = abi.decode(data, (address, address));
        return IERC20(collateralAToken).balanceOf(msg.sender);
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function getRealBorrowAssets(bool, bytes calldata data) external view returns (uint256) {
        (, address borrowVToken) = abi.decode(data, (address, address));
        return IERC20(borrowVToken).balanceOf(msg.sender);
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function initializeLendingConnectorData(bytes memory emode) external {
        address collateralAToken = POOL.getReserveData(address(collateralToken)).aTokenAddress;
        address borrowVToken = POOL.getReserveData(address(borrowToken)).variableDebtTokenAddress;

        require(collateralAToken != address(0), UnsupportedCollateralToken(address(collateralToken)));
        require(borrowVToken != address(0), UnsupportedBorrowToken(address(borrowToken)));

        lendingConnectorGetterData = abi.encode(collateralAToken, borrowVToken);
        uint8 emodeId = uint8(abi.decode(emode, (uint8)));

        if (emodeId != 0) {
            uint16 ltv;
            uint16 liquidationThreshold;
            uint16 liquidationBonus;
            if (block.chainid == 11155111) {
                (ltv, liquidationThreshold, liquidationBonus,,,) = POOL.getEModeCategoryData(emodeId);
            } else {
                (ltv, liquidationThreshold, liquidationBonus) = POOL.getEModeCategoryCollateralConfig(emodeId);
            }
            require(ltv != 0 && liquidationThreshold != 0 && liquidationBonus != 0, InvalidEModeId(emodeId));
        }
        POOL.setUserEMode(emodeId);
    }
}
