// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "src/elements/LTV.sol";
import "src/state_transition/ERC20.sol";
import "src/interfaces/IModules.sol";

contract DummyLTV is LTV, ERC20 {
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

    function setStartAuction(uint64 value) public {
        startAuction = value;
    }

    function mintFreeTokens(uint256 amount, address receiver) public {
        _mint(receiver, amount);
    }

    function burnTokens(uint256 amount, address owner) public {
        _burn(owner, amount);
    }
}
