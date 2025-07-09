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

    // bytes32(uint256(keccak256("ltv.storage.AaveConnector")) - 1)
    bytes32 private constant AaveConnectorStorageLocation =
        0x7b08b9e4e612d3755d3b35a5c73e7f62c5c011a4596e7560d57fe01e6a76f74f;

    struct AaveConnectorStorage {
        address collateralAsset;
        address borrowAsset;
    }

    function _getAaveConnectorStorage() private pure returns (AaveConnectorStorage storage s) {
        assembly {
            s.slot := AaveConnectorStorageLocation
        }
    }

    function supply(uint256 amount) external {
        collateralToken.approve(address(POOL), amount);
        AaveConnectorStorage storage s = _getAaveConnectorStorage();
        POOL.supply(s.collateralAsset, amount, address(this), 0);
    }

    function withdraw(uint256 amount) external {
        AaveConnectorStorage storage s = _getAaveConnectorStorage();
        POOL.withdraw(s.collateralAsset, amount, address(this));
    }

    function borrow(uint256 amount) external {
        AaveConnectorStorage storage s = _getAaveConnectorStorage();
        POOL.borrow(s.borrowAsset, amount, 2, 0, address(this));
    }

    function repay(uint256 amount) external {
        borrowToken.approve(address(POOL), amount);
        AaveConnectorStorage storage s = _getAaveConnectorStorage();
        POOL.repay(s.borrowAsset, amount, 2, address(this));
    }

    function getRealCollateralAssets(bool, bytes calldata data) external view returns (uint256) {
        (address collateralAssetAddress,) = abi.decode(data, (address, address));

        address collateralAToken = POOL.getReserveData(collateralAssetAddress).aTokenAddress;
        return IERC20(collateralAToken).balanceOf(msg.sender);
    }

    function getRealBorrowAssets(bool, bytes calldata data) external view returns (uint256) {
        (, address borrowAssetAddress) = abi.decode(data, (address, address));

        address borrowAToken = POOL.getReserveData(borrowAssetAddress).variableDebtTokenAddress;
        return IERC20(borrowAToken).balanceOf(msg.sender);
    }

    function initializeProtocol(bytes memory data) external {
        (address collateralAssetAddress, address borrowAssetAddress) = abi.decode(data, (address, address));

        AaveConnectorStorage storage s = _getAaveConnectorStorage();
        s.collateralAsset = collateralAssetAddress;
        s.borrowAsset = borrowAssetAddress;

        connectorGetterData = abi.encode(collateralAssetAddress, borrowAssetAddress);
    }
}
