// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {IModules} from "src/interfaces/IModules.sol";
import {LTV} from "src/elements/LTV.sol";
import {ERC20} from "src/state_transition/ERC20.sol";

contract DummyLTV is LTV {
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
}
