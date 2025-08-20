// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {MaxWithdrawRedeemBorrowVaultState} from "src/structs/state/vault/MaxWithdrawRedeemBorrowVaultState.sol";
import {PreviewWithdrawVaultStateReader} from "src/state_reader/vault/PreviewWithdrawVaultStateReader.sol";

contract MaxWithdrawRedeemBorrowVaultStateReader is PreviewWithdrawVaultStateReader {
    function maxWithdrawRedeemBorrowVaultState(address owner)
        internal
        view
        returns (MaxWithdrawRedeemBorrowVaultState memory)
    {
        return MaxWithdrawRedeemBorrowVaultState({
            previewWithdrawVaultState: previewWithdrawVaultState(),
            maxSafeLtvDividend: maxSafeLtvDividend,
            maxSafeLtvDivider: maxSafeLtvDivider,
            ownerBalance: balanceOf[owner]
        });
    }
}
