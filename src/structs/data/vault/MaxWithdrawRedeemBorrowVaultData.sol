// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewWithdrawBorrowVaultData.sol";

struct MaxWithdrawRedeemBorrowVaultData {
    PreviewWithdrawBorrowVaultData previewWithdrawBorrowVaultData;
    uint256 realCollateral;
    uint256 realBorrow;
    uint256 maxSafeLTV;
    uint256 ownerBalance;
}
