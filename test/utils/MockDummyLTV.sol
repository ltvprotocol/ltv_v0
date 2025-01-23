// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../../src/ltv_lendings/DummyLTV.sol";

contract MockDummyLTV is DummyLTV {
    constructor(
        address initialOwner,
        address collateralToken,
        address borrowToken,
        IDummyLending _lendingProtocol,
        IDummyOracle _oracle
    )
        DummyLTV(
            initialOwner,
            collateralToken,
            borrowToken,
            _lendingProtocol,
            _oracle
        )
    {
      
    }

    function setFutureBorrowAssets(int256 value) public {
      futureBorrowAssets = value;
    }

    function setFutureCollateralAssets(int256 value) public {
      futureCollateralAssets = value;
    }

    function setFutureRewardBorrowAssets(int256 value) public {
      futureRewardBorrowAssets = value;
    }

    function setFutureRewardCollateralAssets(int256 value) public {
      futureRewardCollateralAssets = value;
    }

    function setStartAuction(uint256 value) public {
      startAuction = value;
    } 
}
