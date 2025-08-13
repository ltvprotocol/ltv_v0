// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewWithdrawVaultStateReader.sol";
import "src/structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";

contract MaxWithdrawRedeemBorrowVaultStateReader is PreviewWithdrawVaultStateReader {
    function maxWithdrawRedeemBorrowVaultState(address owner)
        internal
        view
        returns (MaxWithdrawRedeemBorrowVaultState memory)
    {
        return MaxWithdrawRedeemBorrowVaultState({
            previewWithdrawVaultState: previewWithdrawVaultState(),
            maxSafeLTVDividend: maxSafeLTVDividend,
            maxSafeLTVDivider: maxSafeLTVDivider,
            ownerBalance: balanceOf[owner]
        });
    }
}
