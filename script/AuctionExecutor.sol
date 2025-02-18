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
        int256 deltaBorrow;
        int256 deltaCollateral;
        if (auctionBorrow > 0) {
            deltaBorrow = -auctionBorrow;
            deltaCollateral = targetContract.previewExecuteAuctionBorrow(deltaBorrow);
            targetContract.collateralToken().approve(address(targetContract), uint256(deltaCollateral));
            targetContract.executeAuctionBorrow(deltaBorrow);
        }
        else if (auctionBorrow < 0) {
            deltaCollateral = targetContract.futureCollateralAssets();
            deltaBorrow = targetContract.previewExecuteAuctionCollateral(deltaCollateral);
            targetContract.borrowToken().approve(address(targetContract), uint256(-deltaBorrow));
            targetContract.executeAuctionCollateral(deltaCollateral);
        }
    }
}
