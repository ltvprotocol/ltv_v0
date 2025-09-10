// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {PreviewWithdrawBorrowVaultData} from "src/structs/data/vault/PreviewWithdrawBorrowVaultData.sol";

/**
 * @title MaxWithdrawRedeemBorrowVaultData
 * @notice This struct needed for max withdraw redeem borrow vault calculations
 */
struct MaxWithdrawRedeemBorrowVaultData {
    PreviewWithdrawBorrowVaultData previewWithdrawBorrowVaultData;
    uint256 realCollateral;
    uint256 realBorrow;
    uint16 maxSafeLtvDividend;
    uint16 maxSafeLtvDivider;
    uint256 ownerBalance;
}
