// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import '../../src/LTV.sol';

contract DummyLTV is LTV {
    uint256 collateralSlippage;
    uint256 borrowSlippage;

    constructor(StateInitData memory initData, address initialOwner, uint256 customCollateralSlippage, uint256 customBorrowSlippage) {
        initialize(initData, initialOwner, 'Dummy LTV', 'DLTV');
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
        return
            Prices({
                borrow: getPriceBorrowOracle(),
                collateral: getPriceCollateralOracle(),
                borrowSlippage: borrowSlippage,
                collateralSlippage: collateralSlippage
            });
    }
}
