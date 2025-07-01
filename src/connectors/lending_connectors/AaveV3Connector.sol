// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../interfaces/ILendingConnector.sol";
import "./interfaces/IAaveV3Pool.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

contract AaveV3Connector is Initializable, ILendingConnector {
    IAaveV3Pool public constant POOL = IAaveV3Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    IERC20 public immutable BORROW_ASSET;
    IERC20 public immutable COLLATERAL_ASSET;
    IERC20 public immutable COLLATERAL_A_TOKEN;
    IERC20 public immutable BORROW_V_TOKEN;

    constructor(IERC20 _borrowAsset, IERC20 _collateralAsset) {
        BORROW_ASSET = _borrowAsset;
        COLLATERAL_ASSET = _collateralAsset;

        COLLATERAL_A_TOKEN = IERC20(POOL.getReserveData(address(COLLATERAL_ASSET)).aTokenAddress);
        BORROW_V_TOKEN = IERC20(POOL.getReserveData(address(BORROW_ASSET)).variableDebtTokenAddress);
    }

    function supply(uint256 amount) external {
        POOL.supply(address(BORROW_ASSET), amount, address(this), 0);
    }

    function withdraw(uint256 amount) external {
        POOL.withdraw(address(BORROW_ASSET), amount, address(this));
    }

    function borrow(uint256 amount) external {
        POOL.borrow(address(BORROW_ASSET), amount, 2, 0, address(this));
    }

    function repay(uint256 amount) external {
        POOL.repay(address(BORROW_ASSET), amount, 2, address(this));
    }

    function getRealCollateralAssets(bool, bytes calldata) external view returns (uint256) {
        return COLLATERAL_A_TOKEN.balanceOf(msg.sender);
    }

    function getRealBorrowAssets(bool, bytes calldata) external view returns (uint256) {
        return BORROW_V_TOKEN.balanceOf(msg.sender);
    }

    function initializeProtocol(bytes memory) external onlyInitializing {
        POOL.setUserEMode(1);
    }
}
