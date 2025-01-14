// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./Constants.sol";

import "./Structs.sol";

import "./Oracles.sol";

import "./utils/MulDiv.sol";

import "./interfaces/IERC20.sol";

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

    IERC20 public collateralToken;
    IERC20 public borrowToken;

    using uMulDiv for uint256;
    using sMulDiv for int256;

    function getAuctionStep() public view returns (uint256) {

        uint256 auctionStep = block.number - startAuction;

        bool stuck = auctionStep > Constants.AMOUNT_OF_STEPS;

        if (stuck) {
            return Constants.AMOUNT_OF_STEPS;
        }

        return auctionStep;
    }

    function recoverConvertedAssets() internal view returns (ConvertedAssets memory) {

        // borrow should be round up
        // because this is the amount that protocol should pay
        int256 realBorrow = int256(getRealBorrowAssets().mulDivUp(getPriceBorrowOracle(), Constants.ORACLE_DEVIDER));

        // collateral should be round down
        // because this is the amount that protocol owns
        int256 realCollateral = int256(getRealCollateralAssets().mulDivDown(getPriceCollateralOracle(), Constants.ORACLE_DEVIDER));

        // futureBorrow should be round down
        // because we want to minimize the amount that protocol will pay to the user
        // TODO: double check this with experts
        int256 futureBorrow = futureBorrowAssets.mulDivDown(int256(getPriceBorrowOracle()), int256(Constants.ORACLE_DEVIDER));

        // futureCollateral should be round up
        // because we want to maximize the amount that protocol will get from the user
        // TODO: double check this with experts
        int256 futureCollateral = futureCollateralAssets.mulDivUp(int256(getPriceCollateralOracle()), int256(Constants.ORACLE_DEVIDER));

        // futureRewardBorrow should be round down
        // because we want to minimize the amount that protocol will pay to the user
        // TODO: double check this with experts
        int256 futureRewardBorrow = futureRewardBorrowAssets.mulDivDown(int256(getPriceBorrowOracle()), int256(Constants.ORACLE_DEVIDER));

        // TODO: precheck futureRewardBorrow >= 0

        // futureRewardCollateral should be round up
        // because we want to maximize the amount that protocol will get from the user
        // TODO: double check this with experts
        int256 futureRewardCollateral = futureRewardCollateralAssets.mulDivUp(int256(getPriceCollateralOracle()), int256(Constants.ORACLE_DEVIDER));

        // TODO: precheck futureRewardCollateral <= 0

        // userFutureRewardBorrow should be round down
        // because we want to minimize the amount that protocol will pay to the user
        // TODO: double check this with experts
        int256 userFutureRewardBorrow = futureRewardBorrow.mulDivDown(int256(getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));

        // userFutureRewardCollateral should be round down
        // because we want to minimize the amount that protocol will pay to the user
        // TODO: double check this with experts
        int256 userFutureRewardCollateral = futureRewardCollateral.mulDivUp(int256(getAuctionStep()), int256(Constants.AMOUNT_OF_STEPS));

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
            userFutureRewardCollateral: userFutureRewardCollateral,
            auctionStep: int256(getAuctionStep())
        });
    }
}
