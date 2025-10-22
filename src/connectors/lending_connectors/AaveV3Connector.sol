// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ILendingConnector} from "src/interfaces/connectors/ILendingConnector.sol";
import {IAaveV3Pool} from "src/connectors/lending_connectors/interfaces/IAaveV3Pool.sol";
import {LTVState} from "src/states/LTVState.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AaveV3Connector
 * @notice Connector for Aave V3 Pool
 */
contract AaveV3Connector is LTVState, ILendingConnector {
    using SafeERC20 for IERC20;

    IAaveV3Pool public immutable POOL;

    constructor(address _pool) {
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
        (, address borrowAToken) = abi.decode(data, (address, address));
        return IERC20(borrowAToken).balanceOf(msg.sender);
    }

    /**
     * @inheritdoc ILendingConnector
     */
    function initializeLendingConnectorData(bytes memory emode) external {
        address collateralAToken = POOL.getReserveData(address(collateralToken)).aTokenAddress;
        address borrowAToken = POOL.getReserveData(address(borrowToken)).variableDebtTokenAddress;

        lendingConnectorGetterData = abi.encode(collateralAToken, borrowAToken);
        POOL.setUserEMode(uint8(abi.decode(emode, (uint256))));
    }
}
