// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import {LTV} from '../src/LTV.sol';

contract AuctionExecutor is Ownable {
    LTV public targetContract;

    constructor(address initialOwner, address ltv) Ownable(initialOwner) {
      targetContract = LTV(ltv);
    }

    function recoverAsset(address asset, uint256 amount) external onlyOwner {
        IERC20(asset).transfer(owner(), amount);
    }

    function setTargetContract(address ltv) external onlyOwner {
        targetContract = LTV(ltv);
    }

    function closeCurrentAuction() external onlyOwner {
        int256 auctionBorrow = targetContract.futureBorrowAssets();
        if (auctionBorrow > 10**17) {
            IERC20 collateralToken = IERC20(address(targetContract.collateralToken()));
            collateralToken.approve(address(targetContract), collateralToken.balanceOf(address(this)));
            targetContract.executeAuctionBorrow(-auctionBorrow);
        }
        else if (auctionBorrow < 10**17) {
            IERC20 borrowToken = IERC20(address(targetContract.borrowToken()));
            borrowToken.approve(address(targetContract), borrowToken.balanceOf(address(this)));
            targetContract.executeAuctionCollateral(-targetContract.futureCollateralAssets());
        }
    }
}
