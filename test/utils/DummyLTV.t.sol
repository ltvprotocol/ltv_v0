// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {LTV} from "src/elements/LTV.sol";

contract DummyLTV is LTV {
    function setLastSeenTokenPrice(uint256 value) public {
        lastSeenTokenPrice = value;
    }

    function setFutureBorrowAssets(int256 value) public {
        futureBorrowAssets = value;
    }

    function setFutureCollateralAssets(int256 value) public {
        futureCollateralAssets = value;
    }

    function setFutureRewardBorrowAssets(int256 value) public {
        require(futureBorrowAssets <= 0);
        require(value >= 0);
        futureRewardBorrowAssets = value;
    }

    function setFutureRewardCollateralAssets(int256 value) public {
        require(futureBorrowAssets >= 0);
        require(value <= 0);
        futureRewardCollateralAssets = value;
    }

    function setStartAuction(uint56 value) public {
        startAuction = value;
    }

    function mintFreeTokens(uint256 amount, address receiver) public {
        balanceOf[receiver] += amount;
        baseTotalSupply += amount;
    }

    function burnTokens(uint256 amount, address owner) public {
        balanceOf[owner] -= amount;
        baseTotalSupply -= amount;
    }

    function setCollateralSlippage(uint256 value) public {
        (uint256 collateralSlippage, uint256 borrowSlippage) =
            abi.decode(slippageConnectorGetterData, (uint256, uint256));
        collateralSlippage = value;
        slippageConnectorGetterData = abi.encode(collateralSlippage, borrowSlippage);
    }

    function setBorrowSlippage(uint256 value) public {
        (uint256 collateralSlippage, uint256 borrowSlippage) =
            abi.decode(slippageConnectorGetterData, (uint256, uint256));
        borrowSlippage = value;
        slippageConnectorGetterData = abi.encode(collateralSlippage, borrowSlippage);
    }

    function getRealBorrowAssets(bool isDeposit) public view returns (uint256) {
        return _getRealBorrowAssets(isDeposit);
    }

    function getRealCollateralAssets(bool isDeposit) public view returns (uint256) {
        return _getRealCollateralAssets(isDeposit);
    }
}
