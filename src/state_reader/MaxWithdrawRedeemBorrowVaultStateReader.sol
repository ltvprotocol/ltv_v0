// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "./PreviewVaultStateReader.sol";
import "src/structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";

contract MaxWithdrawRedeemBorrowVaultStateReader is PreviewVaultStateReader {
    function maxWithdrawRedeemBorrowVaultState(address owner)
        internal
        view
        returns (MaxWithdrawRedeemBorrowVaultState memory)
    {
        return MaxWithdrawRedeemBorrowVaultState({
            previewVaultState: previewVaultState(),
            maxSafeLTV: maxSafeLTV,
            ownerBalance: balanceOf[owner]
        });
    }
}
