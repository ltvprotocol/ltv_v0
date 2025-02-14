// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../../src/ltv_lendings/DummyLTV.sol';

contract MockDummyLTV is DummyLTV {
    uint256 collateralSlippage;
    uint256 borrowSlippage;

    constructor(
        address initialOwner,
        address collateralToken,
        address borrowToken,
        IDummyLending _lendingProtocol,
        IDummyOracle _oracle,
        uint256 customCollateralSlippage,
        uint256 customBorrowSlippage,
        address feeCollector
    ) DummyLTV(initialOwner, collateralToken, borrowToken, _lendingProtocol, _oracle, feeCollector) {
        collateralSlippage = customCollateralSlippage;
        borrowSlippage = customBorrowSlippage;
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

    function mintFreeTokens(uint256 amount, address receiver) public {
        _mint(receiver, amount);
    }

    function burnTokens(uint256 amount, address owner) public {
        _burn(owner, amount);
    }

    function setCollateralSlippage(uint256 value) public {
        collateralSlippage = value;
    }

    function setBorrowSlippage(uint256 value) public {
        borrowSlippage = value;
    }

    function getPrices() internal view override returns (Prices memory) {
        Prices memory prices = super.getPrices();
        prices.collateralSlippage = collateralSlippage;
        prices.borrowSlippage = borrowSlippage;
        return prices;
    }
}
