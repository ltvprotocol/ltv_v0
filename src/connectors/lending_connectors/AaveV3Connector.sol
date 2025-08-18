// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../interfaces/ILendingConnector.sol";
import "./interfaces/IAaveV3Pool.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {LTVState} from "../../states/LTVState.sol";
import "forge-std/console.sol";

contract AaveV3Connector is LTVState, ILendingConnector {
    IAaveV3Pool public constant POOL = IAaveV3Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    function supply(uint256 amount) external {
        collateralToken.approve(address(POOL), amount);
        POOL.supply(address(collateralToken), amount, address(this), 0);
    }

    function withdraw(uint256 amount) external {
        POOL.withdraw(address(collateralToken), amount, address(this));
    }

    function borrow(uint256 amount) external {
        POOL.borrow(address(borrowToken), amount, 2, 0, address(this));
    }

    function repay(uint256 amount) external {
        borrowToken.approve(address(POOL), amount);
        POOL.repay(address(borrowToken), amount, 2, address(this));
    }

    function getRealCollateralAssets(bool, bytes calldata data) external view returns (uint256) {
        (address collateralAToken,) = abi.decode(data, (address, address));
        return IERC20(collateralAToken).balanceOf(msg.sender);
    }

    function getRealBorrowAssets(bool, bytes calldata data) external view returns (uint256) {
        (, address borrowAToken) = abi.decode(data, (address, address));
        return IERC20(borrowAToken).balanceOf(msg.sender);
    }

    function initializeProtocol(bytes memory) external {
        address collateralAToken = POOL.getReserveData(address(collateralToken)).aTokenAddress;
        address borrowAToken = POOL.getReserveData(address(borrowToken)).variableDebtTokenAddress;

        connectorGetterData = abi.encode(collateralAToken, borrowAToken);
    }
}
