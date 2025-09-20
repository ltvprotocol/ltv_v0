# Auction roundings 

### List of all auction's math roundings:

| Rounding number | Function name | First factor | Second factor | Denominator |
| --- | --- | --- | --- | --- |
| 1 | calculateDeltaFutureBorrowAssetsFromDeltaUserBorrowAssets | deltaUserBorrowAssets * int256(auctionDuration) | futureBorrowAssets | int256(auctionDuration) * futureBorrowAssets + auctionStep * futureRewardBorrowAssets |
| 2 | calculateDeltaFutureCollateralAssetsFromDeltaUserCollateralAssets | deltaUserCollateralAssets * int256(auctionDuration) | futureCollateralAssets | int256(auctionDuration) * futureCollateralAssets + auctionStep * futureRewardCollateralAssets |
| 3 | calculateDeltaFutureBorrowAssetsFromDeltaFutureCollateralAssets | deltaFutureCollateralAssets | futureBorrowAssets | futureCollateralAssets |
| 4 | calculateDeltaFutureCollateralAssetsFromDeltaFutureBorrowAssets | deltaFutureBorrowAssets | futureCollateralAssets | futureBorrowAssets |
| 5 | calculateDeltaFutureRewardBorrowAssetsFromDeltaFutureBorrowAssets | futureRewardBorrowAssets | deltaFutureBorrowAssets | futureBorrowAssets |
| 6 | calculateDeltaFutureRewardCollateralAssetsFromDeltaFutureCollateralAssets | futureRewardCollateralAssets | deltaFutureCollateralAssets | futureCollateralAssets |
| 7 | calculateDeltaUserFutureRewardBorrowAssetsFromDeltaFutureRewardBorrowAssets | deltaFutureRewardBorrowAssets | auctionStep | auctionDuration |
| 8 | calculateDeltaUserFutureRewardCollateralAssetsFromDeltaFutureRewardCollateralAssets | deltaFutureRewardCollateralAssets | auctionStep | auctionDuration |

### List of all auction write functions and order of function calls during it's execution

| Function name | Function calls order |
| --- | --- |
| executeAuctionBorrow | 1, 4, 6, 8 |
| executeAuctionCollateral | 2, 3, 5, 7 |