// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewDepositBorrowVaultData} from "../preview/PreviewDepositBorrowVaultData.sol";

/**
 * @title MaxDepositMintBorrowVaultData
 * @notice This struct needed for max deposit mint borrow vault calculations
 */
struct MaxDepositMintBorrowVaultData {
    PreviewDepositBorrowVaultData previewDepositBorrowVaultData;
    uint256 realCollateral;
    uint256 realBorrow;
    uint256 maxTotalAssetsInUnderlying;
    uint16 minProfitLtvDividend;
    uint16 minProfitLtvDivider;
}
