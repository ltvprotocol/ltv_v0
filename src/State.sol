// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./Constants.sol";

import "./Structs.sol";

import "./Oracles.sol";

abstract contract State is Oracles {
    int256 public futureBorrowAssets;
    int256 public futureCollateralAssets;
    int256 public futureRewardBorrowAssets;
    int256 public futureRewardCollateralAssets;
    uint256 public startAuction;

    // ERC 20 state
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;

    function getAuctionStep() public view returns (uint256) {

        uint256 auctionStep = block.number - startAuction;

        bool stuck = auctionStep > Constants.AMOUNT_OF_STEPS;

        if (stuck) {
            return Constants.AMOUNT_OF_STEPS;
        }

        return auctionStep;
    }

    function recoverConvertedAssets() internal view returns (ConvertedAssets memory) {

        int256 realBorrow = int256(getRealBorrowAssets() * getPriceBorrowOracle() / Constants.ORACLE_DEVIDER);
        int256 realCollateral = int256(getRealCollateralAssets() * getPriceCollateralOracle() / Constants.ORACLE_DEVIDER);

        int256 futureBorrow = futureBorrowAssets * int256(getPriceBorrowOracle()) / int256(Constants.ORACLE_DEVIDER);
        int256 futureCollateral = futureCollateralAssets * int256(getPriceCollateralOracle()) / int256(Constants.ORACLE_DEVIDER);

        int256 futureRewardBorrow = futureRewardBorrowAssets * int256(getPriceBorrowOracle()) / int256(Constants.ORACLE_DEVIDER);
        int256 futureRewardCollateral = futureRewardCollateralAssets * int256(getPriceCollateralOracle()) / int256(Constants.ORACLE_DEVIDER);

        int256 userFutureRewardBorrow = futureRewardBorrow * int256(getAuctionStep()) / int256(Constants.AMOUNT_OF_STEPS);
        int256 userFutureRewardCollateral = futureRewardCollateral * int256(getAuctionStep()) / int256(Constants.AMOUNT_OF_STEPS);

        int256 protocolFutureRewardBorrow = futureRewardBorrow - userFutureRewardBorrow;
        int256 protocolFutureRewardCollateral = futureRewardCollateral - userFutureRewardCollateral;

        int256 borrow = realBorrow + futureBorrow + futureRewardBorrow;
        int256 collateral = realCollateral + futureCollateral + futureRewardCollateral;

        return ConvertedAssets({
            borrow: borrow,
            collateral: collateral,
            realBorrow: realBorrow,
            realCollateral: realCollateral,
            futureBorrow: futureBorrow,
            futureCollateral: futureCollateral,
            futureRewardBorrow: futureRewardBorrow,
            futureRewardCollateral: futureRewardCollateral,
            protocolFutureRewardBorrow: protocolFutureRewardBorrow,
            protocolFutureRewardCollateral: protocolFutureRewardCollateral,
            userFutureRewardBorrow: userFutureRewardBorrow,
            userFutureRewardCollateral: userFutureRewardCollateral
        });
    }
}
